/**
 * @description A container for particle properties, similar to GM's part_type.
 */
function UeParticleType() constructor {
    gml_pragma("forceinline");
    // Life
    self.lifeMin = 1.0;
    self.lifeMax = 1.0;
    
    // Size
    self.sizeMin = 1.0;
    self.sizeMax = 1.0;
    self.sizeIncr = 0.0;
    self.sizeWiggle = 0.0;
    
    // Speed & Direction (Radians)
    self.speedMin = 0.0;
    self.speedMax = 0.0;
    self.speedIncr = 0.0;
    self.speedWiggle = 0.0;
    
    self.dirMin = 0.0;
    self.dirMax = 2 * pi;
    self.dirIncr = 0.0;
    self.dirWiggle = 0.0;
    
    // Gravity (Radians)
    self.gravAmount = 0.0;
    self.gravDir = 1.5 * pi; // 270 degrees in radians
    
    self.zSpeedMin = 0.0;
    self.zSpeedMax = 0.0;
    self.zSpeedIncr = 0.0;
    self.zSpeedWiggle = 0.0;
    self.zGravAmount = 0.0;
    
    // Rotation (Radians)
    self.rotMin = 0.0;
    self.rotMax = 0.0;
    self.rotIncr = 0.0;
    self.rotWiggle = 0.0;
    
    // Color & Alpha (using arrays [r,g,b] for internal processing)
    self.colorStart = [1.0, 1.0, 1.0];
    self.colorEnd   = [1.0, 1.0, 1.0];
    self.alphaStart = 1.0;
    self.alphaEnd   = 1.0;
    
    // Visuals
    self.sprite = -1;
    self.texture = -1;
    self.uvs = [0, 0, 1, 1]; // [x, y, w, h]
    self.additive = false;

    // Feature Flags & Pre-calculations (Auto-calculated for optimization)
    self.hasWiggle = false;
    self.hasGravity = false;
    self.hasColorOverLife = false;
    self.hasAlphaOverLife = false;
    self.hasSizeOverLife = false;
    self.hasRotation = false;
    self.hasPhysics = false; // speed, direction, gravity

    // Range Diffs
    self.lifeDiff = 0.0;
    self.sizeDiff = 0.0;
    self.speedDiff = 0.0;
    self.zSpeedDiff = 0.0;
    self.dirDiff = 0.0;
    self.rotDiff = 0.0;
    
    // Pre-computed vectors
    self.gravX = 0.0;
    self.gravY = 0.0;

    self.setShape("sphere");

    /**
     * Re-calculates feature flags and diffs to optimize update loop and spawning.
     */
    static updateFlags = function() {
        gml_pragma("forceinline");
        self.hasWiggle = (self.sizeWiggle != 0 || self.speedWiggle != 0 || self.zSpeedWiggle != 0 || self.dirWiggle != 0 || self.rotWiggle != 0);
        self.hasGravity = (self.gravAmount != 0 || self.zGravAmount != 0);
        self.hasColorOverLife = (self.colorStart[0] != self.colorEnd[0] || self.colorStart[1] != self.colorEnd[1] || self.colorStart[2] != self.colorEnd[2]);
        self.hasAlphaOverLife = (self.alphaStart != self.alphaEnd);
        self.hasSizeOverLife = (self.sizeIncr != 0 || self.sizeWiggle != 0);
        self.hasRotation = (self.rotMin != 0 || self.rotMax != 0 || self.rotIncr != 0 || self.rotWiggle != 0);
        self.hasPhysics = (self.speedMin != 0 || self.speedMax != 0 || self.speedIncr != 0 || self.zSpeedMin != 0 || self.zSpeedMax != 0 || self.zSpeedIncr != 0 || self.dirIncr != 0 || self.hasGravity);
        
        // Pre-calculate diffs
        self.lifeDiff = self.lifeMax - self.lifeMin;
        self.sizeDiff = self.sizeMax - self.sizeMin;
        self.speedDiff = self.speedMax - self.speedMin;
        self.zSpeedDiff = self.zSpeedMax - self.zSpeedMin;
        self.dirDiff = self.dirMax - self.dirMin;
        self.rotDiff = self.rotMax - self.rotMin;
        
        // Pre-calculate gravity vectors
        self.gravX = cos(self.gravDir) * self.gravAmount;
        self.gravY = -sin(self.gravDir) * self.gravAmount;
        
        return self;
    }

    // Fluent API Methods
    static setLife = function(minVal, maxVal) {
        gml_pragma("forceinline");
        self.lifeMin = minVal;
        self.lifeMax = maxVal;
        return self;
    }
    
    static setSize = function(minVal, maxVal, incr = 0, wiggle = 0) {
        gml_pragma("forceinline");
        self.sizeMin = minVal;
        self.sizeMax = maxVal;
        self.sizeIncr = incr;
        self.sizeWiggle = wiggle;
        self.updateFlags();
        return self;
    }
    
    static setSpeed = function(zMin, zMax, xyMin = 0, xyMax = 0, zIncr = 0, xyIncr = 0, zWiggle = 0, xyWiggle = 0) {
        gml_pragma("forceinline");
        self.zSpeedMin = zMin;
        self.zSpeedMax = zMax;
        self.zSpeedIncr = zIncr;
        self.zSpeedWiggle = zWiggle;
        
        self.speedMin = xyMin;
        self.speedMax = xyMax;
        self.speedIncr = xyIncr;
        self.speedWiggle = xyWiggle;
        
        self.updateFlags();
        return self;
    }
    
    static setDirection = function(minVal, maxVal, incr = 0, wiggle = 0) {
        gml_pragma("forceinline");
        self.dirMin = degtorad(minVal);
        self.dirMax = degtorad(maxVal);
        self.dirIncr = degtorad(incr);
        self.dirWiggle = degtorad(wiggle);
        self.updateFlags();
        return self;
    }
    
    static setGravity = function(amountZ, amountXY = 0, dirXY = 270) {
        gml_pragma("forceinline");
        self.zGravAmount = amountZ;
        self.gravAmount = amountXY;
        self.gravDir = degtorad(dirXY);
        self.updateFlags();
        return self;
    }
    
    static setRotation = function(minVal, maxVal, incr = 0, wiggle = 0) {
        gml_pragma("forceinline");
        self.rotMin = degtorad(minVal);
        self.rotMax = degtorad(maxVal);
        self.rotIncr = degtorad(incr);
        self.rotWiggle = degtorad(wiggle);
        self.updateFlags();
        return self;
    }
    
    static setColor = function(color1, color2 = undefined) {
        gml_pragma("forceinline");
        self.colorStart = [color_get_red(color1)/255, color_get_green(color1)/255, color_get_blue(color1)/255];
        if (color2 != undefined) {
            self.colorEnd = [color_get_red(color2)/255, color_get_green(color2)/255, color_get_blue(color2)/255];
        } else {
            self.colorEnd = self.colorStart;
        }
        self.updateFlags();
        return self;
    }
    
    static setAlpha = function(alpha1, alpha2 = undefined) {
        gml_pragma("forceinline");
        self.alphaStart = alpha1;
        self.alphaEnd = (alpha2 != undefined) ? alpha2 : alpha1;
        self.updateFlags();
        return self;
    }
    
    static setAdditive = function(enable) {
        gml_pragma("forceinline");
        self.additive = enable;
        return self;
    }
    
    static setSprite = function(sprite, subimg = 0) {
        gml_pragma("forceinline");
        self.sprite = sprite;
        if (sprite_exists(sprite)) {
            self.texture = sprite_get_texture(sprite, subimg);
            var _uvs = sprite_get_uvs(sprite, subimg);
            self.uvs = [_uvs[0], _uvs[1], _uvs[2] - _uvs[0], _uvs[3] - _uvs[1]];
        }
        return self;
    }

    /**
     * Set a procedural shape from the global renderer.
     * @param {string} shapeName "point", "sphere", "flare", "square", "box", "disk", "ring"
     */
    static setShape = function(shapeName) {
        gml_pragma("forceinline");
        var _shape = global.UE_PARTICLE_RENDERER.shapes[$ shapeName];
        if (_shape != undefined) {
            self.texture = _shape.texture;
            self.uvs = _shape.uvs;
        }
        return self;
    }
}
