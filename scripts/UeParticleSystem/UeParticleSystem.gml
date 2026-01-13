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
  self.sortingEnabled = false;

  static addEmitter = function (emitter) {
    gml_pragma("forceinline");
    array_push(self.emitters, emitter);
    return emitter;
  }

  static update = function (dt = undefined, cx = undefined, cy = undefined, cz = undefined) {
    gml_pragma("forceinline");
    if (!self.enabled) return;

    if (dt == undefined) { 
      static _dtCache = 0; static _lastFrame = -1;
      if (current_time != _lastFrame) {
        _dtCache = delta_time / 1000000; _lastFrame = current_time;
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
  * Renders all emitters using their internal persistent buffers.
  */ 
  static render = function (camera = undefined) {
    gml_pragma("forceinline");
    if (!self.enabled) return;
    camera ??= view_camera[0];

    var emitters = self.emitters;
    var culling = self.frustumCulling;
    var _bm = gpu_get_blendmode();

    for (var i = 0, il = array_length(emitters); i < il; i++) {
      var emitter = emitters[i];
      
      if (culling) {
          emitter.visible = sphere_is_visible(emitter.centerX, emitter.centerY, emitter.centerZ, emitter.cullingRadius);
      } else { emitter.visible = true; }

      if (emitter.visible && emitter.pool.aliveCount > 0) {
        var type = emitter.streamType;
        if (type != undefined) {
            gpu_set_blendmode(type.additive ? bm_add : bm_normal);
            emitter.render(camera);
        }
      }
    }
    gpu_set_blendmode(_bm);
  }

  static getTotalParticles = function () {
    var total = 0;
    for (var i = 0; i < array_length(self.emitters); i++) total += self.emitters[i].pool.aliveCount;
    return total;
  }
}
