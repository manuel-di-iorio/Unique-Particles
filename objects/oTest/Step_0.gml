// Update Camera
if (mouse_check_button(mb_left)) {
    camYaw += (display_mouse_get_x() - pmouse_x) * 0.5;
    camPitch = clamp(camPitch + (display_mouse_get_y() - pmouse_y) * 0.5, -89, 89);
}

// Camera Zoom
if (mouse_wheel_up()) camDist = max(10, camDist - 10);
if (mouse_wheel_down()) camDist = min(2000, camDist + 10);

pmouse_x = display_mouse_get_x();
pmouse_y = display_mouse_get_y();

var xydist = camDist * cos(degtorad(camPitch));
var cx = lengthdir_x(xydist, camYaw);
var cy = lengthdir_y(xydist, camYaw);
var cz = camDist * sin(degtorad(camPitch));

var viewMat = matrix_build_lookat(cx, cy, cz, 0, 0, 0, 0, 0, -1);
camera_set_view_mat(view_camera[0], viewMat);

// Update Particle System
particleSystem.update(delta_time / 1000000);
