draw_set_color(c_white);
draw_set_font(-1);

var totalAlive = 0;
var yy = 10;
var emitters = particleSystem.emitters;

for (var i = 0; i < array_length(emitters); i++) {
    var e = emitters[i];
    var count = e.pool.aliveCount;
    totalAlive += count;
    draw_text(10, yy, "Emitter " + string(i) + ": " + string(count) + " particles");
    yy += 20;
}

draw_text(10, yy + 10, "Total Particles: " + string(totalAlive));
draw_text(10, yy + 30, "FPS: " + string(fps) + " (Real: " + string(floor(fpsAvg)) + ")");

var helpY = window_get_height() - 150;
draw_text(10, helpY,       "PRESS 1: Bonfire");
draw_text(10, helpY + 20,  "PRESS 2: Explosion");
draw_text(10, helpY + 40,  "PRESS 3: Rain");
draw_text(10, helpY + 60,  "PRESS 4: Snow");
draw_text(10, helpY + 80,  "PRESS 5: Fireworks");
draw_text(10, helpY + 100, "SPACE: Burst (Explosion/Fireworks)");
draw_text(10, helpY + 125, "LClick + Drag: Rotate Camera | Wheel: Zoom");
