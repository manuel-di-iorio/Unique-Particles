/**
* @description Persistent emitter. Writes to a buffer once and lets the GPU do the heavy lifting.
*/
function UeParticleEmitter(maxParticles = 5000) constructor {
  gml_pragma("forceinline");
  self.maxParticles = maxParticles;
  self.vformat = global.UE_PARTICLE_RENDER_FORMAT;
  self.vsize = 52; // 52 bytes per vertex (3*4 Pos + 4 Color + 2*4 Corner + 4*4 VelTime + 3*4 LifeSizeRot)
  
  // RAW Buffer persistent (CPU-side)
  self.rawBuffer = buffer_create(maxParticles * 6 * self.vsize, buffer_fixed, 1);
  buffer_fill(self.rawBuffer, 0, buffer_f32, 0, buffer_get_size(self.rawBuffer));
  
  self.vbuffer = undefined;
  self.writePointer = 0; // Circular pointer
  self.spawnedAny = false;

  // Initial State
  self.streamType = undefined;
  self.streamRate = 0;
  self._accumulator = 0;
  self.enabled = true;
  self.centerX = 0; self.centerY = 0; self.centerZ = 0;
  self.sizeX = 0; self.sizeY = 0; self.sizeZ = 0;
  self.shape = "point";
  self.visible = true;
  self.pool = { aliveCount: 0 }; 

  // LOD & Culling settings
  self.lodDistances = [500, 1000];
  self.lodRates = [1.0, 0.5, 0.1];
  self.lodLevel = 0;
  self.cullingRadius = 100;
  self.autoCullingRadius = true;

  /**
   * Updates LOD level based on distance to camera.
   */
  static updateLOD = function(cx, cy, cz) {
    gml_pragma("forceinline");
    var dist = point_distance_3d(cx, cy, cz, self.centerX, self.centerY, self.centerZ);
    var _dists = self.lodDistances;
    
    self.lodLevel = 0;
    for (var i = 0, il = array_length(_dists); i < il; i++) {
        if (dist > _dists[i]) {
            self.lodLevel = i + 1;
        } else {
            break;
        }
    }
    return self.lodLevel;
  }

  /**
   * Estimates the maximum radius particles can reach from the center.
   */
  static computeCullingRadius = function() {
    gml_pragma("forceinline");
    var type = self.streamType;
    var baseR = max(self.sizeX, self.sizeY, self.sizeZ) * 0.5;
    if (type == undefined) {
        self.cullingRadius = baseR;
        return self;
    }

    // Analytical travel: (v0*t + 0.5*a*t^2)
    var maxLife = type.lifeMax;
    var maxV = max(abs(type.speedMax), abs(type.zSpeedMax));
    var maxA = max(abs(type.gravAmount), abs(type.zGravAmount)); 
    var travel = maxV * maxLife + 0.5 * maxA * maxLife * maxLife;

    self.cullingRadius = baseR + travel;
    return self;
  }

  static region = function (s, x1, y1, z1, x2, y2, z2) {
    self.shape = s; self.centerX = (x1 + x2) * 0.5; self.centerY = (y1 + y2) * 0.5; self.centerZ = (z1 + z2) * 0.5;
    self.sizeX = abs(x2 - x1); self.sizeY = abs(y2 - y1); self.sizeZ = abs(z2 - z1); 
    self.computeCullingRadius();
    return self;
  }

  static stream = function (t, r) { 
    self.streamType = t; 
    self.streamRate = r; 
    self.computeCullingRadius();
    return self; 
  }

  /**
  * Spawns a particle by writing 6 vertices into the circular buffer.
  */
  static spawn = function (type) {
    var sx = self.centerX, sy = self.centerY, sz = self.centerZ;
    if (self.shape == "box") {
        sx += random_range(-0.5, 0.5) * self.sizeX; sy += random_range(-0.5, 0.5) * self.sizeY; sz += random_range(-0.5, 0.5) * self.sizeZ;
    }
    var spd = random_range(type.speedMin, type.speedMax), dir = random_range(type.dirMin, type.dirMax);
    var vx = cos(dir) * spd, vy = -sin(dir) * spd, vz = random_range(type.zSpeedMin, type.zSpeedMax);
    var life = random_range(type.lifeMin, type.lifeMax);
    var sS = random_range(type.sizeMin, type.sizeMax), rS = random_range(type.rotMin, type.rotMax);
    var cs = (floor(type.alphaStart*255)<<24) | (floor(type.colorStart[2]*255)<<16) | (floor(type.colorStart[1]*255)<<8) | floor(type.colorStart[0]*255);
    var st = current_time / 1000.0;

    // --- Circular Write (O(1)) ---
    var b = self.rawBuffer;
    var offset = self.writePointer * 6 * self.vsize;
    buffer_seek(b, buffer_seek_start, offset);
    
    // Corners: TL, TR, BL, BL, TR, BR (Triangle List 6 verts)
    static cornersX = [-0.5, 0.5, -0.5, -0.5, 0.5, 0.5];
    static cornersY = [-0.5, -0.5, 0.5, 0.5, -0.5, 0.5];
    
    for (var c = 0; c < 6; c++) {
        buffer_write(b, buffer_f32, sx); buffer_write(b, buffer_f32, sy); buffer_write(b, buffer_f32, sz);
        buffer_write(b, buffer_u32, cs);
        buffer_write(b, buffer_f32, cornersX[c]); buffer_write(b, buffer_f32, cornersY[c]);
        buffer_write(b, buffer_f32, vx); buffer_write(b, buffer_f32, vy); buffer_write(b, buffer_f32, vz); buffer_write(b, buffer_f32, st);
        buffer_write(b, buffer_f32, life); buffer_write(b, buffer_f32, sS); buffer_write(b, buffer_f32, rS);
    }
    
    self.writePointer = (self.writePointer + 1) % self.maxParticles;
    self.spawnedAny = true;
    self.pool.aliveCount = self.maxParticles; 
  }

  static update = function (dt) {
    if (self.enabled && self.streamType != undefined && self.streamRate > 0) {
      self._accumulator += dt * self.streamRate * self.lodRates[self.lodLevel];
      while (self._accumulator >= 1) { self.spawn(self.streamType); self._accumulator--; }
    }
  }

  static render = function (camera) {
    if (self.spawnedAny) {
        if (self.vbuffer != undefined) vertex_delete_buffer(self.vbuffer);
        self.vbuffer = vertex_create_buffer_from_buffer(self.rawBuffer, self.vformat);
        vertex_freeze(self.vbuffer);
        self.spawnedAny = false;
    }
    if (self.vbuffer == undefined || self.streamType == undefined) return;
    global.UE_PARTICLE_RENDERER.submit(self, camera, self.streamType);
  }
}
