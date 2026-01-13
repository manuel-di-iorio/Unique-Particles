global.UE_PARTICLE_RENDERER_VERSION = "0.0.1";

/**
 * @description Efficient renderer for particle systems using vertex batching and a dedicated shader.
 */
function UeParticleRenderer(_shaders = {}) constructor {
  gml_pragma("forceinline");

  // ===== Vertex Format =====
  vertex_format_begin();
  vertex_format_add_position_3d(); // Center position
  vertex_format_add_colour();      // Color and 2 corner id bits
  vertex_format_add_custom(vertex_type_float2, vertex_usage_texcoord); // size, rot
  self.format = vertex_format_end();

  self.vbuffer = vertex_create_buffer();

  // ===== Shader =====
  self.shader = _shaders[$ "main"] ?? sh_ue_particle;

  // ===== Uniforms =====
  self.uRight = shader_get_uniform(self.shader, "u_ueCameraRight");
  self.uUp = shader_get_uniform(self.shader, "u_ueCameraUp");
  self.uUVRegion = shader_get_uniform(self.shader, "u_ueUVRegion");
  self.uTime = shader_get_uniform(self.shader, "u_ueTime");

  // Cache for view matrix extraction
  static _vmCache = array_create(16, 0);

  // ===== Fallback Texture (Soft Circle) =====
  self.fallbackTexture = -1;
  var _res = 64;
  var _surf = surface_create(_res, _res);
  surface_set_target(_surf);
  draw_clear_alpha(c_black, 0);

  // Draw a soft radial gradient
  gpu_set_blendmode(bm_add);
  for (var i = 0; i < _res / 2; i++) {
    var _alpha = (1.0 - (i / (_res / 2))) * 0.5;
    draw_set_alpha(_alpha);
    draw_circle_color(_res / 2, _res / 2, i, c_white, c_white, false);
  }
  draw_set_alpha(1.0);
  gpu_set_blendmode(bm_normal);

  surface_reset_target();
  self.fallbackSprite = sprite_create_from_surface(_surf, 0, 0, _res, _res, false, false, _res / 2, _res / 2);
  self.fallbackTexture = sprite_get_texture(self.fallbackSprite, 0);

  surface_free(_surf);

  /**
   * Render particles
   */
  function render(pool, camera, texture = -1, uvs = undefined) {
    gml_pragma("forceinline");

    var count = pool.aliveCount;
    if (count == 0) return;

    // Use fallback if no texture provided
    var tex = texture == -1 ? self.fallbackTexture : texture;

    // Get UVs if not provided
    if (uvs == undefined) {
      var _uvs = texture_get_uvs(tex);
      uvs = [_uvs[0], _uvs[1], _uvs[2] - _uvs[0], _uvs[3] - _uvs[1]];
    }

    // ===== Camera Right / Up (world space) =====
    // Get camera view matrix to extract Right and Up vectors for billboarding
    var vm = camera_get_view_mat(camera);

    // Copy to static cache to avoid array creation/overhead if needed by other systems
    array_copy(_vmCache, 0, vm, 0, 16);

    // In a view matrix, the Right vector is the first column (or row depending on convention)
    // For GM: [0, 4, 8] is Right, [1, 5, 9] is Up
    var rx = _vmCache[0];
    var ry = _vmCache[4];
    var rz = _vmCache[8];

    var ux = _vmCache[1];
    var uy = _vmCache[5];
    var uz = _vmCache[9];

    // ===== Build Vertex Buffer =====
    vertex_begin(self.vbuffer, self.format);

    var _posX = pool.posX;
    var _posY = pool.posY;
    var _posZ = pool.posZ;
    var _size = pool.size;
    var _rot = pool.rot;
    var _alpha = pool.alpha;
    var _r = pool.colorR;
    var _g = pool.colorG;
    var _b = pool.colorB;
    var _active = pool.activeIndices;

    static corners = [0, 1, 2, 2, 3, 0];

    for (var i = 0; i < count; i++) {
      var idx = _active[i];
      var px = _posX[idx];
      var py = _posY[idx];
      var pz = _posZ[idx];
      var size = _size[idx];
      var rot = _rot[idx];
      var r_base = floor(_r[idx] * 255) & ~1;
      var g = floor(_g[idx] * 255);
      var b_base = floor(_b[idx] * 255) & ~1;
      var a = _alpha[idx];

      // Pre-calculate colors for the 4 unique corners to avoid make_color_rgb in loop
      // Corner 0: (0,0), Corner 1: (1,0), Corner 2: (1,1), Corner 3: (0,1)
      var c0 = r_base | (g << 8) | (b_base << 16);
      var c1 = (r_base | 1) | (g << 8) | (b_base << 16);
      var c2 = (r_base | 1) | (g << 8) | ((b_base | 1) << 16);
      var c3 = r_base | (g << 8) | ((b_base | 1) << 16);

      // Unrolled loop for 6 vertices (2 triangles: 0-1-2 and 2-3-0)
      // Triangle 1
      vertex_position_3d(self.vbuffer, px, py, pz);
      vertex_color(self.vbuffer, c0, a);
      vertex_float2(self.vbuffer, size, rot);

      vertex_position_3d(self.vbuffer, px, py, pz);
      vertex_color(self.vbuffer, c1, a);
      vertex_float2(self.vbuffer, size, rot);

      vertex_position_3d(self.vbuffer, px, py, pz);
      vertex_color(self.vbuffer, c2, a);
      vertex_float2(self.vbuffer, size, rot);

      // Triangle 2
      vertex_position_3d(self.vbuffer, px, py, pz);
      vertex_color(self.vbuffer, c2, a);
      vertex_float2(self.vbuffer, size, rot);

      vertex_position_3d(self.vbuffer, px, py, pz);
      vertex_color(self.vbuffer, c3, a);
      vertex_float2(self.vbuffer, size, rot);

      vertex_position_3d(self.vbuffer, px, py, pz);
      vertex_color(self.vbuffer, c0, a);
      vertex_float2(self.vbuffer, size, rot);
    }

    vertex_end(self.vbuffer);

    // ===== Submit =====
    shader_set(self.shader);
    shader_set_uniform_f(self.uTime, current_time / 1000.0);
    shader_set_uniform_f_array(self.uUVRegion, uvs);
    shader_set_uniform_f(self.uRight, rx, ry, rz);
    shader_set_uniform_f(self.uUp, ux, uy, uz);

    var _blend = gpu_get_blendenable();
    var _zwrite = gpu_get_zwriteenable();
    var _ztest = gpu_get_ztestenable();

    gpu_set_blendenable(true);
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(false);

    vertex_submit(self.vbuffer, pr_trianglelist, tex);

    gpu_set_blendenable(_blend);
    gpu_set_zwriteenable(_zwrite);
    gpu_set_ztestenable(_ztest);

    shader_reset();
  }

  function dispose() {
    gml_pragma("forceinline");
    vertex_delete_buffer(self.vbuffer);
    if (sprite_exists(self.fallbackSprite)) {
      sprite_delete(self.fallbackSprite);
    }
  }
}

global.UE_PARTICLE_RENDERER = new UeParticleRenderer();
