particleSystem = new UeParticleSystem();
particleSystem.setPosition(0, 0, 15);

// Initial Effect
currentEffect = "bonfire";
scr_effect_bonfire(particleSystem);

// --- Camera 3D Test ---
gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);
camDist = 500;
camYaw = -45;
camPitch = 25;
pmouse_x = display_mouse_get_x();
pmouse_y = display_mouse_get_y();
camera = camera_create();
var projMat = matrix_build_projection_perspective_fov(60, window_get_width() / window_get_height(), 1, 32000);
camera_set_proj_mat(camera, projMat);
view_set_camera(0, camera);

// Create Floor VBuffer (Grid)
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_color();
vertex_format_add_texcoord();
floorFormat = vertex_format_end();

floorVBuffer = vertex_create_buffer();
vertex_begin(floorVBuffer, floorFormat);
var s = 1000;
var step = 50;
var c = c_dkgray;

for (var i = -s; i <= s; i += step) {
  // Lines along X
  vertex_position_3d(floorVBuffer, i, -s, 0); vertex_color(floorVBuffer, c, 1); vertex_texcoord(floorVBuffer, 0, 0);
  vertex_position_3d(floorVBuffer, i, s, 0); vertex_color(floorVBuffer, c, 1); vertex_texcoord(floorVBuffer, 0, 0);

  // Lines along Y
  vertex_position_3d(floorVBuffer, -s, i, 0); vertex_color(floorVBuffer, c, 1); vertex_texcoord(floorVBuffer, 0, 0);
  vertex_position_3d(floorVBuffer, s, i, 0); vertex_color(floorVBuffer, c, 1); vertex_texcoord(floorVBuffer, 0, 0);
}
vertex_end(floorVBuffer);
vertex_freeze(floorVBuffer);

fpsAvg = fps_real;
