/** 
* @description Manages a group of emitters and handles their rendering. 
* Similar to GM's part_system. 
*/
function UeParticleSystem() constructor {
  gml_pragma("forceinline");
  self.emitters = [];
  self.renderer = global.UE_PARTICLE_RENDERER;
  self.enabled = true;

  // LOD & Culling settings
  self.lodEnabled = true;
  self.frustumCulling = true;
  self.sortingEnabled = true;

  /** 
  * Adds an emitter to the system. 
  */ 
  static addEmitter = function (emitter) {
    gml_pragma("forceinline");
    array_push(self.emitters, emitter);
    return emitter;
  }

  /** 
  * Updates all emitters in the system. 
  * @param {real} dt Delta time in seconds.
  * @param {real} cx Camera X (optional, for LOD).
  * @param {real} cy Camera Y (optional, for LOD).
  * @param {real} cz Camera Z (optional, for LOD).
  */ 
  static update = function (dt = undefined, cx = undefined, cy = undefined, cz = undefined) {
    gml_pragma("forceinline");
    if (!self.enabled) return;

    if (dt == undefined) { 
      static _dtCache = 0;
      static _lastFrame = -1;

      if (current_time != _lastFrame) {
        _dtCache = delta_time / 1000000;
        _lastFrame = current_time;
      }
      dt = _dtCache;
    }

    var emitters = self.emitters;
    var lod = self.lodEnabled && (cx != undefined);

    for (var i = 0, il = array_length(emitters); i < il; i++) {
      var emitter = emitters[i];
      if (lod) emitter.updateLOD(cx, cy, cz);
      emitter.update(dt);
    }
  }

  /** 
  * Renders all emitters in the system. 
  */ 
  static render = function (camera = undefined, texture = -1) {
    gml_pragma("forceinline");
    if (!self.enabled || self.renderer == undefined) return;
    camera ??= view_camera[0];

    // Separate additive from normal emitters without array_push (faster with counters) 
    static normalEmitters = array_create(128); 
    static additiveEmitters = array_create(128);
    var normalCount = 0;
    var additiveCount = 0;

    var emitters = self.emitters;
    var culling = self.frustumCulling;

    for (var i = 0, il = array_length(emitters); i < il; i++) {
      var emitter = emitters[i];
      
      // Perform Frustum Culling 
      if (culling) {
          emitter.visible = sphere_is_visible(emitter.centerX, emitter.centerY, emitter.centerZ, emitter.cullingRadius);
      } else {
          emitter.visible = true;
      }

      if (emitter.visible && emitter.pool.aliveCount > 0) {
        var type = emitter.streamType;
        if (type != undefined && type.additive) {
          additiveEmitters[additiveCount++] = emitter;
        } else {
          normalEmitters[normalCount++] = emitter;
        }
      }
    }

    var _bm = gpu_get_blendmode();
    var renderer = self.renderer;

    // Normal batch render 
    if (normalCount > 0) {
      gpu_set_blendmode(bm_normal);
      for (var i = 0; i < normalCount; i++) {
        var emitter = normalEmitters[i];
        var type = emitter.streamType;
        var tex = texture;
        var uvs = undefined;
        if (tex == -1 && type != undefined) {
          tex = type.texture;
          uvs = type.uvs;
        }
        renderer.render(emitter.pool, camera, tex, uvs, self.sortingEnabled);
      }
      renderer.flush();
    }

    // Additive batch render 
    if (additiveCount > 0) {
      gpu_set_blendmode(bm_add);
      for (var i = 0; i < additiveCount; i++) {
        var emitter = additiveEmitters[i];
        var type = emitter.streamType;
        var tex = texture;
        var uvs = undefined;
        if (tex == -1 && type != undefined) {
          tex = type.texture;
          uvs = type.uvs;
        }
        renderer.render(emitter.pool, camera, tex, uvs, false);
      }
      renderer.flush();
    }

    gpu_set_blendmode(_bm);
  }

  /** 
  * Returns the total number of alive particles in all emitters. 
  */ 
  static getTotalParticles = function () {
    gml_pragma("forceinline");
    var total = 0;
    var emitters = self.emitters;
    for (var i = 0, il = array_length(emitters); i < il; i++) {
      total += emitters[i].pool.aliveCount;
    }
    return total;
  }
}
