/**
 * @description Manages a group of emitters and handles their rendering.
 * Similar to GM's part_system.
 */
function UeParticleSystem() constructor {
    gml_pragma("forceinline");
    self.emitters = [];
    self.renderer = global.UE_PARTICLE_RENDERER;
    self.enabled = true;

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
     */
    static update = function (dt = undefined) {
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

        for (var i = 0, il = array_length(self.emitters); i < il; i++) {
            self.emitters[i].update(dt);
        }
    }

    /**
     * Renders all emitters in the system.
     */
    static draw = function (camera = undefined, texture = -1) {
        gml_pragma("forceinline");
        if (!self.enabled || self.renderer == undefined) return;
        camera ??= view_camera[0];

        // Separa emitters additivi da normali senza array_push (più veloce con contatori)
        static normalEmitters = array_create(128);
        static additiveEmitters = array_create(128);
        var normalCount = 0;
        var additiveCount = 0;

        var emitters = self.emitters;
        for (var i = 0, il = array_length(emitters); i < il; i++) {
            var emitter = emitters[i];
            if (emitter.pool.aliveCount > 0) {
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

        // Render batch normale
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
                renderer.render(emitter.pool, camera, tex, uvs);
            }
        }

        // Render batch additivo
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
                renderer.render(emitter.pool, camera, tex, uvs);
            }
        }

        gpu_set_blendmode(_bm);
    }
}
