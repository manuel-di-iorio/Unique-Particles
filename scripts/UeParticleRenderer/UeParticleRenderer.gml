global.UE_PARTICLE_RENDER_FORMAT = undefined;

function UeParticleRenderer(_shaders = {}) constructor {
  gml_pragma("forceinline");

  // ===== Vertex Format (52 bytes: Leggerissimo!) =====
  if (global.UE_PARTICLE_RENDER_FORMAT == undefined) {
    vertex_format_begin();
    vertex_format_add_position_3d();                                      // 12 bytes
    vertex_format_add_colour();                                           // 4 bytes
    vertex_format_add_custom(vertex_type_float2, vertex_usage_texcoord);   // 8 bytes (CornerXY)
    vertex_format_add_custom(vertex_type_float4, vertex_usage_texcoord);   // 16 bytes (VelXYZ + SpawnTime)
    vertex_format_add_custom(vertex_type_float3, vertex_usage_texcoord);   // 12 bytes (MaxLife, sStart, rStart)
    global.UE_PARTICLE_RENDER_FORMAT = vertex_format_end();
  }
  self.format = global.UE_PARTICLE_RENDER_FORMAT;

  self.shader = _shaders[$ "main"] ?? sh_ue_particle;
  self.uRight = shader_get_uniform(self.shader, "u_ueCameraRight");
  self.uUp = shader_get_uniform(self.shader, "u_ueCameraUp");
  self.uUVRegion = shader_get_uniform(self.shader, "u_ueUVRegion");
  self.uTime = shader_get_uniform(self.shader, "u_ueTime");
  
  self.uGrav   = shader_get_uniform(self.shader, "u_ueGravity");
  self.uSizeE  = shader_get_uniform(self.shader, "u_ueSizeEnd");
  self.uColE   = shader_get_uniform(self.shader, "u_ueColorEnd");
  self.uRotSpd = shader_get_uniform(self.shader, "u_ueRotSpeed");

  // ===== Procedural Shape Generator (Restored) =====
  self.shapes = {};
  static __createShape = function (_name, _drawFunc) {
    var _res = 64;
    var _surf = surface_create(_res, _res);
    if (!surface_exists(_surf)) return undefined;
    surface_set_target(_surf);
    draw_clear_alpha(c_black, 0); _drawFunc(_res);
    surface_reset_target();
    var _spr = sprite_create_from_surface(_surf, 0, 0, _res, _res, false, false, _res/2, _res/2);
    surface_free(_surf);
    var _tex = sprite_get_texture(_spr, 0), _uvs = texture_get_uvs(_tex);
    self.shapes[$ _name] = { texture: _tex, uvs: [_uvs[0], _uvs[1], _uvs[2]-_uvs[0], _uvs[3]-_uvs[1]] };
    return self.shapes[$ _name];
  };

  self.__createShape("point", function(r) { draw_circle(r/2, r/2, r/2-2, false); });
  self.__createShape("sphere", function(r) {
    gpu_set_blendmode(bm_add);
    for(var i=0; i<r/2; i++) { draw_set_alpha((1-i/(r/2))*0.5); draw_circle(r/2, r/2, i, false); }
    gpu_set_blendmode(bm_normal); draw_set_alpha(1.0);
  });
  self.__createShape("flare", function(r) {
      var m = r/2; draw_set_alpha(0.5);
      for(var i=0; i<r/2; i++) { draw_line_width(m-i, m, m+i, m, 2); draw_line_width(m, m-i, m, m+i, 2); }
      draw_set_alpha(1); draw_circle(m, m, r/6, false);
  });

  self.fallbackTexture = self.shapes.sphere.texture;

  static submit = function(emitter, camera, type) {
      gml_pragma("forceinline");
      shader_set(self.shader);
      var vm = camera_get_view_mat(camera);
      shader_set_uniform_f(self.uTime, current_time / 1000.0);
      shader_set_uniform_f_array(self.uUVRegion, type.uvs);
      shader_set_uniform_f(self.uRight, vm[0], vm[4], vm[8]);
      shader_set_uniform_f(self.uUp, vm[1], vm[5], vm[9]);
      
      shader_set_uniform_f(self.uGrav, type.gravX, type.gravY, type.zGravAmount);
      shader_set_uniform_f(self.uSizeE, type.sizeMin + type.sizeIncr * type.lifeMax);
      shader_set_uniform_f(self.uColE, type.colorEnd[0], type.colorEnd[1], type.colorEnd[2], type.alphaEnd);
      shader_set_uniform_f(self.uRotSpd, type.rotIncr);

      gpu_set_zwriteenable(false);
      vertex_submit(emitter.vbuffer, pr_trianglelist, type.texture);
      gpu_set_zwriteenable(true);
      shader_reset();
  }
}

global.UE_PARTICLE_RENDERER = new UeParticleRenderer();
