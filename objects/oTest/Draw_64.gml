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
draw_text(10, yy + 30, "FPS: " + string(fps) + " (Real: " + string(fps_real) + ")");
