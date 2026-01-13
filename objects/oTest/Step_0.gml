// Update Camera
if (mouse_check_button(mb_left)) {
    camYaw += (display_mouse_get_x() - pmouse_x) * 0.5;
    camPitch = clamp(camPitch + (display_mouse_get_y() - pmouse_y) * 0.5, -89, 89);
}

// Camera Zoom
if (mouse_wheel_up()) camDist = max(10, camDist - 20);
if (mouse_wheel_down()) camDist = min(2000, camDist + 20);

pmouse_x = display_mouse_get_x();
pmouse_y = display_mouse_get_y();

var xydist = camDist * cos(degtorad(camPitch));
var cx = lengthdir_x(xydist, camYaw);
var cy = lengthdir_y(xydist, camYaw);
var cz = camDist * sin(degtorad(camPitch));

var viewMat = matrix_build_lookat(cx, cy, cz, 0, 0, 0, 0, 0, -1);
camera_set_view_mat(view_camera[0], viewMat);

// Switch Effects
if (keyboard_check_pressed(ord("1"))) { currentEffect = "bonfire"; scr_effect_bonfire(particleSystem); }
if (keyboard_check_pressed(ord("2"))) { currentEffect = "explosion"; scr_effect_explosion(particleSystem); }
if (keyboard_check_pressed(ord("3"))) { currentEffect = "rain"; scr_effect_rain(particleSystem); }
if (keyboard_check_pressed(ord("4"))) { currentEffect = "snow"; scr_effect_snow(particleSystem); }
if (keyboard_check_pressed(ord("5"))) { currentEffect = "fireworks"; scr_effect_fireworks(particleSystem); }

// Space Burst
if (keyboard_check_pressed(vk_space)) {
    if (currentEffect == "explosion") {
        if (variable_instance_exists(particleSystem, "explosion_trigger") || variable_struct_exists(particleSystem, "explosion_trigger")) {
            particleSystem.explosion_trigger();
        }
    }
    if (currentEffect == "fireworks") {
        if (variable_instance_exists(particleSystem, "firework_launch") || variable_struct_exists(particleSystem, "firework_launch")) {
            particleSystem.firework_launch();
        }
    }
}

// Update Particle System
particleSystem.update(delta_time / 1000000, cx, cy, cz);

fpsAvg = lerp(fpsAvg, fps_real, 0.1);
