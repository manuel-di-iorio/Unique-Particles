particleSystem = new UeParticleSystem();

// --- Smoke Type ---
smokeType = new UeParticleType()
    .setLife(2.5, 4.0)
    .setSpeed(30, 50, 3, 20, -2)
    .setDirection(0, 360, 0, 40)
    .setSize(50, 100, 50)
    .setRotation(0, 360, 30, 5)
    .setColor(#333333, #111111)
    .setAlpha(0.3, 0.0); // Much lower alpha to avoid covering fire

smokeEmitter = new UeParticleEmitter(800);
smokeEmitter.region("box", -25, -25, 30, 25, 25, 50); // Start higher (Z=30)
smokeEmitter.stream(smokeType, 35); // Lower density

// --- Fire Type ---
fireType = new UeParticleType()
    .setLife(0.3, 0.6)
    .setSpeed(130, 220, 8, 20, -60, 0, 50, 15)
    .setDirection(0, 360, 0, 60)
    .setSize(45, 75, -40, 20)
    .setRotation(0, 360, 350, 150)
    .setColor(#FFDD55, #FF4400) // Brighter yellow-to-red
    .setAlpha(1.0, 0.0)
    .setAdditive(true)
    .setGravity(35);

fireEmitter = new UeParticleEmitter(1500);
fireEmitter.region("box", -15, -15, 0, 15, 15, 5);
fireEmitter.stream(fireType, 550);

// --- Embers ---
emberType = new UeParticleType()
    .setLife(1.2, 2.5)
    .setSpeed(60, 150, 15, 50, 0, 0, 0, 30)
    .setDirection(0, 360, 50, 20)
    .setSize(3, 6, -3)
    .setColor(#FFCC00, #FF3300)
    .setAlpha(1.0, 0.0)
    .setAdditive(true)
    .setGravity(15);

emberEmitter = new UeParticleEmitter(400);
emberEmitter.region("box", -25, -25, 0, 25, 25, 15);
emberEmitter.stream(emberType, 60);

// ADD EMITTERS (Order matters for drawing: Smoke first, then Fire on top)
particleSystem.addEmitter(smokeEmitter);
particleSystem.addEmitter(fireEmitter);
particleSystem.addEmitter(emberEmitter);

// --- Camera 3D Test ---
gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);
camDist = 400;
camYaw = 20;
camPitch = 10;
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
