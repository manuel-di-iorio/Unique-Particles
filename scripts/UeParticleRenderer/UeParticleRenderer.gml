global.UE_PARTICLE_RENDERER_VERSION = "0.0.1";

/**
 * @description Advanced particle renderer with texture batching and procedural shapes.
 */
function UeParticleRenderer(_shaders = {}) constructor {
  gml_pragma("forceinline");

  // ===== Vertex Format (24 bytes per vertex) =====
  vertex_format_begin();
  vertex_format_add_position_3d();
  vertex_format_add_colour();     
  vertex_format_add_custom(vertex_type_float2, vertex_usage_texcoord);
  vertex_format_add_custom(vertex_type_float3, vertex_usage_texcoord); // Velocity (vx, vy, vz)
  self.format = vertex_format_end();

  self.vbuffer = vertex_create_buffer();
  self.renderQueue = [];

  // ===== Shader & Uniforms =====
  self.shader = _shaders[$ "main"] ?? sh_ue_particle;
  self.uRight = shader_get_uniform(self.shader, "u_ueCameraRight");
  self.uUp = shader_get_uniform(self.shader, "u_ueCameraUp");
  self.uUVRegion = shader_get_uniform(self.shader, "u_ueUVRegion");
  self.uTime = shader_get_uniform(self.shader, "u_ueTime");
  self.uInterpolation = shader_get_uniform(self.shader, "u_ueInterpolation");

  static _vmCache = array_create(16, 0);

  // ===== Procedural Shape Generator =====
  self.shapes = {};
  static __createShape = function (_name, _drawFunc) {
    var _res = 64;
    var _surf = surface_create(_res, _res);
    if (!surface_exists(_surf)) return undefined;
    surface_set_target(_surf);
    draw_clear_alpha(c_black, 0);
    _drawFunc(_res);
    surface_reset_target();
    var _spr = sprite_create_from_surface(_surf, 0, 0, _res, _res, false, false, _res/2, _res/2);
    surface_free(_surf);
    var _tex = sprite_get_texture(_spr, 0);
    var _uvs = texture_get_uvs(_tex);
    self.shapes[$ _name] = { sprite: _spr, texture: _tex, uvs: [_uvs[0], _uvs[1], _uvs[2]-_uvs[0], _uvs[3]-_uvs[1]] };
    return self.shapes[$ _name];
  };

  // Basic Shapes
  self.__createShape("point", function(r) { draw_circle(r/2, r/2, r/2-2, false); });
  self.__createShape("sphere", function(r) {
    gpu_set_blendmode(bm_add);
    for(var i=0; i<r/2; i++) { draw_set_alpha((1-i/(r/2))*0.5); draw_circle(r/2, r/2, i, false); }
    gpu_set_blendmode(bm_normal); draw_set_alpha(1.0);
  });
  
  // Advanced Shapes
  self.__createShape("flare", function(r) {
      var m = r/2; draw_set_alpha(0.5);
      for(var i=0; i<r/2; i++) { draw_line_width(m-i, m, m+i, m, 2); draw_line_width(m, m-i, m, m+i, 2); }
      draw_set_alpha(1); draw_circle(m, m, r/6, false);
  });
  
  self.__createShape("shockwave", function(r) {
      draw_set_circle_precision(64);
      for(var i=0; i<4; i++) draw_circle(r/2, r/2, r/2-4-i, true);
      draw_set_alpha(0.2); draw_circle(r/2, r/2, r/3, false);
      draw_set_alpha(1.0);
  });

  self.__createShape("cloud", function(r) {
      repeat(30) {
          draw_set_alpha(random_range(0.1, 0.3));
          draw_circle(r/2 + random_range(-10, 10), r/2 + random_range(-10, 10), random_range(5, 20), false);
      }
      draw_set_alpha(1.0);
  });

  self.__createShape("spark", function(r) {
      draw_line_width(4, r/2, r-4, r/2, 3);
      draw_circle(4, r/2, 1.5, false); draw_circle(r-4, r/2, 1.5, false);
  });

  self.fallbackTexture = self.shapes.sphere.texture;
  self.fallbackUVs = self.shapes.sphere.uvs;
  self.autoSort = false;

  function render(pool, camera, texture = -1, uvs = undefined) {
    gml_pragma("forceinline");
    if (pool.aliveCount == 0) return;
    var tex = (texture == -1) ? self.fallbackTexture : texture;
    var _uvs = uvs ?? ((texture == -1) ? self.fallbackUVs : undefined);
    if (_uvs == undefined) {
        var t = texture_get_uvs(tex);
        _uvs = [t[0], t[1], t[2]-t[0], t[3]-t[1]];
    }
    var interp = (pool[$ "emitter"] != undefined) ? pool.emitter._dtAccumulator : 0;
    array_push(self.renderQueue, { pool: pool, camera: camera, texture: tex, uvs: _uvs, interpolation: interp });
  }

  function flush() {
      var count = array_length(self.renderQueue);
      if (count == 0) return;
      
      // Batch sort by texture
      array_sort(self.renderQueue, function(a, b) {
          if (a.texture == b.texture) return 0;
          return (string(a.texture) > string(b.texture)) ? 1 : -1;
      });

      var currentTex = -1;
      var batchStart = 0;
      for (var i = 0; i <= count; i++) {
          var tex = (i < count) ? self.renderQueue[i].texture : -2;
          if (tex != currentTex || i == count) {
              if (currentTex != -1) self.__submitBatch(batchStart, i);
              if (i < count) { currentTex = tex; batchStart = i; }
          }
      }
      array_resize(self.renderQueue, 0);
  }

  static __submitBatch = function(start, stop) {
      var first = self.renderQueue[start];
      var vm = camera_get_view_mat(first.camera);
      array_copy(_vmCache, 0, vm, 0, 16);
      
      vertex_begin(self.vbuffer, self.format);
      for (var k = start; k < stop; k++) {
          var q = self.renderQueue[k];
          var pool = q.pool;
          if (self.autoSort) {
              var cx = -(vm[0]*vm[12] + vm[1]*vm[13] + vm[2]*vm[14]);
              var cy = -(vm[4]*vm[12] + vm[5]*vm[13] + vm[6]*vm[14]);
              var cz = -(vm[8]*vm[12] + vm[9]*vm[13] + vm[10]*vm[14]);
              pool.depthSort(cx, cy, cz);
          }
          
          var pCount = pool.aliveCount, active = pool.activeIndices;
          var pX = pool.posX, pY = pool.posY, pZ = pool.posZ;
          var pS = pool.size, pR = pool.rot, pA = pool.alpha;
          var cR = pool.colorR, cG = pool.colorG, cB = pool.colorB;
          
          // Velocity components for interpolation
          var vX = pool.dirX, vY = pool.dirY, vS = pool.speed, vZ = pool.zSpeed;
          var pVX = pool.velX, pVY = pool.velY, pVZ = pool.velZ;

          for (var j = 0; j < pCount; j++) {
              var idx = active[j];
              var _x = pX[idx], _y = pY[idx], z = pZ[idx], s = pS[idx], rot = pR[idx], a = pA[idx];
              var rb = floor(cR[idx]*255)&~1, g = floor(cG[idx]*255), bb = floor(cB[idx]*255)&~1;
              var c0 = rb|(g<<8)|(bb<<16), c1 = (rb|1)|(g<<8)|(bb<<16), c2 = (rb|1)|(g<<8)|((bb|1)<<16), c3 = rb|(g<<8)|((bb|1)<<16);
              
              // Calculate total instantaneous velocity
              var vx = (vX[idx] * vS[idx] + pVX[idx]);
              var vy = (vY[idx] * vS[idx] + pVY[idx]);
              var vz = (vZ[idx] + pVZ[idx]);

              vertex_position_3d(self.vbuffer, _x, _y, z); vertex_color(self.vbuffer, c0, a); vertex_float2(self.vbuffer, s, rot); vertex_float3(self.vbuffer, vx, vy, vz);
              vertex_position_3d(self.vbuffer, _x, _y, z); vertex_color(self.vbuffer, c1, a); vertex_float2(self.vbuffer, s, rot); vertex_float3(self.vbuffer, vx, vy, vz);
              vertex_position_3d(self.vbuffer, _x, _y, z); vertex_color(self.vbuffer, c2, a); vertex_float2(self.vbuffer, s, rot); vertex_float3(self.vbuffer, vx, vy, vz);
              vertex_position_3d(self.vbuffer, _x, _y, z); vertex_color(self.vbuffer, c2, a); vertex_float2(self.vbuffer, s, rot); vertex_float3(self.vbuffer, vx, vy, vz);
              vertex_position_3d(self.vbuffer, _x, _y, z); vertex_color(self.vbuffer, c3, a); vertex_float2(self.vbuffer, s, rot); vertex_float3(self.vbuffer, vx, vy, vz);
              vertex_position_3d(self.vbuffer, _x, _y, z); vertex_color(self.vbuffer, c0, a); vertex_float2(self.vbuffer, s, rot); vertex_float3(self.vbuffer, vx, vy, vz);
          }
      }
      vertex_end(self.vbuffer);

      shader_set(self.shader);
      shader_set_uniform_f(self.uTime, current_time/1000.0);
      shader_set_uniform_f_array(self.uUVRegion, first.uvs);
      shader_set_uniform_f(self.uRight, _vmCache[0], _vmCache[4], _vmCache[8]);
      shader_set_uniform_f(self.uUp, _vmCache[1], _vmCache[5], _vmCache[9]);
      shader_set_uniform_f(self.uInterpolation, first.interpolation);
      
      var b = gpu_get_blendenable(), zw = gpu_get_zwriteenable(), zt = gpu_get_ztestenable();
      gpu_set_blendenable(true); gpu_set_ztestenable(true); gpu_set_zwriteenable(false);
      vertex_submit(self.vbuffer, pr_trianglelist, first.texture);
      gpu_set_blendenable(b); gpu_set_zwriteenable(zw); gpu_set_ztestenable(zt);
      shader_reset();
  };

  function dispose() {
    vertex_delete_buffer(self.vbuffer);
    var names = variable_struct_get_names(self.shapes);
    for(var i=0; i<array_length(names); i++) sprite_delete(self.shapes[$ names[i]].sprite);
  }
}

global.UE_PARTICLE_RENDERER = new UeParticleRenderer();
