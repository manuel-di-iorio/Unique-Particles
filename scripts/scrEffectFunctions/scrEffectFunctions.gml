function scr_effect_bonfire(sys) {
    sys.clear();

    // Smoke
    var smokeType = new UeParticleType()
        .setLife(2.5, 4.0)
        .setSpeed(30, 50, 3, 20, -2)
        .setDirection(0, 360, 0, 40)
        .setSize(50, 100, 50)
        .setRotation(0, 360, 30, 5)
        .setColor($333333, $111111)
        .setAlpha(0.3, 0.0)
        .setShape("smoke"); // USE NEW SHAPE

    var smokeEmitter = new UeParticleEmitter(800);
    smokeEmitter.region("box", -25, -25, 30, 25, 25, 50);
    smokeEmitter.stream(smokeType, 35);

    // Fire
    var fireType = new UeParticleType()
        .setLife(0.3, 0.6)
        .setSpeed(130, 220, 8, 20, -60, 0, 50, 15)
        .setDirection(0, 360, 0, 60)
        .setSize(45, 75, -40, 20)
        .setRotation(0, 360, 350, 150)
        .setColor($55DDFF, $0044FF)
        .setAlpha(1.0, 0.0)
        .setAdditive(true)
        .setGravity(35)
        .setShape("smoke");

    var fireEmitter = new UeParticleEmitter(1500);
    fireEmitter.region("box", -15, -15, 0, 15, 15, 5);
    fireEmitter.stream(fireType, 550);

    // Embers
    var emberType = new UeParticleType()
        .setLife(1.2, 2.5)
        .setSpeed(60, 150, 15, 50, 0, 0, 0, 30)
        .setDirection(0, 360, 50, 20)
        .setSize(3, 6, -3)
        .setColor($00CCFF, $0033FF)
        .setAlpha(1.0, 0.0)
        .setAdditive(true)
        .setGravity(15);

    var emberEmitter = new UeParticleEmitter(400);
    emberEmitter.region("box", -25, -25, 0, 25, 25, 15);
    emberEmitter.stream(emberType, 60);

    sys.addEmitter(smokeEmitter);
    sys.addEmitter(fireEmitter);
    sys.addEmitter(emberEmitter);
}

function scr_effect_explosion(sys) {
    sys.clear();

    // 1. INCANDESCENT CORE (The "White Hole" start)
    var flashType = new UeParticleType()
        .setLife(0.1, 0.2)
        .setSize(40, 100, 150)
        .setColor(c_white, c_yellow)
        .setGlow(5.0) // HIGH INTENSITY FLASH
        .setAlpha(1.0, 0.0)
        .setAdditive(true)
        .setShape("sphere");

    // 2. MAIN FIRE EXPLOSION (Using 3-way gradient and glow)
    var fireballType = new UeParticleType()
        .setLife(0.4, 0.9)
        .setSpeed(400, 800, 200, 400)
        .setDirection(0, 360)
        .setSize(160, 280, -80)
        .setRotation(0, 360, 500, 200)
        // 3-Way: White -> Orange -> Dark Red
        .setColor(c_white, $000044, $0088FF, 0.15) 
        .setGlow(2.5) // EMISSIVE BOOST
        .setAlpha(0.9, 0.0)
        .setAdditive(true)
        .setDrag(1.8)
        .setShape("smoke");

    // 3. ROLLING DARK SMOKE (NORMAL BLENDING for high contrast)
    var smokeType = new UeParticleType()
        .setLife(2.0, 4.0)
        .setSpeed(120, 300, 60, 180)
        .setDirection(0, 360)
        .setGravity(-20)
        .setSize(220, 500, 120)
        .setRotation(0, 360, 10, 5)
        .setColor($101010, $252525, $151515, 0.5) 
        .setAlpha(0.7, 0.0)
        .setAdditive(false) 
        .setDrag(1.0)
        .setShape("smoke");

    // 4. SUPER-FAST HOT SPARKS (With Glow)
    var sparkType = new UeParticleType()
        .setLife(0.6, 1.5)
        .setSpeed(1000, 2000, 400, 800)
        .setGravity(800)
        .setSize(2, 6)
        .setColor(c_white, c_orange)
        .setGlow(4.0) // BRIGHT SPARKS
         .setAlpha(1.0, 0.0)
         .setAdditive(true);

    // Emitters Configuration
    var eSmoke  = new UeParticleEmitter(1000).stream(smokeType, 0); 
    var eSpark  = new UeParticleEmitter(1200).stream(sparkType, 0);
    var eFire   = new UeParticleEmitter(1500).stream(fireballType, 0);
    var eFlash  = new UeParticleEmitter(100).stream(flashType, 0);

    // Add order: Smoke (back), then everything else on top
    sys.addEmitter(eSmoke);
    sys.addEmitter(eSpark);
    sys.addEmitter(eFire);
    sys.addEmitter(eFlash);

    sys.explosion_trigger = method({
        sm: eSmoke, sp: eSpark, fi: eFire, fl: eFlash,
        smt: smokeType, spt: sparkType, fit: fireballType, flt: flashType
    }, function () {
        sm.burst(smt, 450); 
        sp.burst(spt, 250);
        fi.burst(fit, 600);
        fl.burst(flt, 3);
    });

    sys.explosion_trigger();
}

function scr_effect_rain(sys) {
    sys.clear();

    var rainType = new UeParticleType()
        .setLife(1.0, 1.5)
        .setSpeed(-1500, -2500, 20, 50)
        .setSize(4, 6)
        .setScale(0.1, 8.0)
        .setColor($FFCCAA, $CC9977)
        .setAlpha(0.8, 0.2)
        .setShape("square");

    var rainEmitter = new UeParticleEmitter(5000);
    rainEmitter.region("box", -800, -800, 800, 800, 800, 1000);
    rainEmitter.stream(rainType, 4000);

    sys.addEmitter(rainEmitter);
}

function scr_effect_snow(sys) {
    sys.clear();

    var snowType = new UeParticleType()
        .setLife(10, 15)
        .setSpeed(-50, -100, 20, 50)
        .setDirection(0, 360, 40, 20)
        .setSize(6, 16)
        .setColor($FFFFFF, $EEEEEE)
        .setAlpha(0.8, 0.0)
        .setShape("sphere");

    var snowEmitter = new UeParticleEmitter(4000);
    snowEmitter.region("box", -800, -800, 300, 800, 800, 500);
    snowEmitter.stream(snowType, 600);

    sys.addEmitter(snowEmitter);
}

function scr_effect_fireworks(sys) {
    sys.clear();

    var trailType = new UeParticleType()
        .setLife(0.8, 1.2)
        .setSpeed(600, 1000, 0, 10)
        .setScale(0.3, 3.0)
        .setColor($CCEEFF, $00AAFF)
        .setAlpha(1.0, 0.0)
        .setAdditive(true)
        .setShape("square");

    var starType = new UeParticleType()
        .setLife(1.8, 2.8)
        .setSpeed(-150, 150, 300, 600)
        .setGravity(180)
        .setSize(20, 35, -15)
        .setColor(c_white, c_white)
        .setAlpha(1.0, 0.0)
        .setAdditive(true)
        .setShape("flare");

    var sparkleType = new UeParticleType()
        .setLife(2.0, 3.5)
        .setSpeed(-50, 50, 100, 200)
        .setGravity(250)
        .setSize(5, 10, -3)
        .setColor(c_white, c_yellow)
        .setAlpha(1.0, 0.0)
        .setAdditive(true)
        .setShape("point");

    var trailEmitter = new UeParticleEmitter(1000).stream(trailType, 0);
    var starEmitter = new UeParticleEmitter(4000).stream(starType, 0);
    var sparkEmitter = new UeParticleEmitter(2000).stream(sparkleType, 0);

    sys.addEmitter(trailEmitter);
    sys.addEmitter(starEmitter);
    sys.addEmitter(sparkEmitter);

    sys.firework_launch = method({ t: trailEmitter, s: starEmitter, sp: sparkEmitter, tt: trailType, st: starType, spt: sparkleType }, function () {
        var tx = random_range(-500, 500);
        var ty = random_range(-500, 500);
        var exPos = random_range(250, 450); // Lowered altitude

        t.region("point", tx, ty, 0, tx, ty, 0);
        t.burst(tt, 70);

        var delay = random_range(0.5, 0.7); // Adjusted delay for lower height
        call_later(delay, time_source_units_seconds, method({ s: s, sp: sp, st: st, spt: spt, tx: tx, ty: ty, ez: exPos }, function () {
            var col = choose(c_red, c_aqua, c_yellow, c_lime, c_fuchsia, c_white);
            st.setColor(col, c_white);

            s.region("sphere", tx - 20, ty - 20, ez - 20, tx + 20, ty + 20, ez + 20);
            s.burst(st, 600);

            sp.region("sphere", tx - 40, ty - 40, ez - 40, tx + 40, ty + 40, ez + 40);
            sp.burst(spt, 300);
        }));
    });

    sys.firework_launch();
}
