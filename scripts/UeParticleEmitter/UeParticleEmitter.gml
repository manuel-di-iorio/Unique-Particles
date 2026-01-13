/**
 * @description Handles particle spawning, management and lifecycle logic.
 * Each emitter now owns its own pool of particles.
 */
function UeParticleEmitter(maxParticles = 1000) constructor {
  gml_pragma("forceinline");
  self.pool = new UeParticlePool(maxParticles);

  // Emission state
  self.streamType = undefined;
  self.streamRate = 0;
  self._accumulator = 0;
  self.enabled = true;

  // Region/Shape
  self.shape = "point"; // "point", "box", "sphere"
  self.x1 = 0; self.y1 = 0; self.z1 = 0;
  self.x2 = 0; self.y2 = 0; self.z2 = 0;
  self.centerX = 0; self.centerY = 0; self.centerZ = 0;
  self.sizeX = 0; self.sizeY = 0; self.sizeZ = 0;

    /**
     * Sets the region/shape of the emitter.
     */
    static region = function (shape, x1, y1, z1, x2, y2, z2) {
    gml_pragma("forceinline");
    self.shape = shape;
    self.x1 = x1; self.y1 = y1; self.z1 = z1;
    self.x2 = x2; self.y2 = y2; self.z2 = z2;
    self.centerX = (x1 + x2) * 0.5;
    self.centerY = (y1 + y2) * 0.5;
    self.centerZ = (z1 + z2) * 0.5;
    self.sizeX = abs(x2 - x1);
    self.sizeY = abs(y2 - y1);
    self.sizeZ = abs(z2 - z1);
    return self;
  }

    /**
     * Sets the emitter to stream a specific type at a specific rate.
     */
    static stream = function (type, rate) {
    gml_pragma("forceinline");
    self.streamType = type;
    self.streamRate = rate;
    return self;
  }

    /**
     * Bursts a specific number of particles of a given type.
     */
    static burst = function (type, count) {
    gml_pragma("forceinline");
    if (type == undefined || count <= 0) return self;
    repeat(count) self.spawn(type);
    return self;
  }

    /**
     * Spawns a single particle of the given type.
     */
    static spawn = function (type) {
    gml_pragma("forceinline");

        // Use the same random table for spawn to avoid random() calls
        static randomTableSize = 1024;
        static randomTable = undefined;
        static randomIndex = 0;
    if (randomTable == undefined) {
      randomTable = array_create(randomTableSize);
      for (var _r = 0; _r < randomTableSize; _r++) randomTable[_r] = random(1.0);
    }

    var p = self.pool;
    var i = p.allocate();
    if (i == -1) return -1;

    // --- Spawn Position ---
    var sx = self.centerX;
    var sy = self.centerY;
    var sz = self.centerZ;

    if (self.shape == "box") {
      sx += (randomTable[randomIndex++ & 1023] * 2.0 - 1.0) * self.sizeX * 0.5;
      sy += (randomTable[randomIndex++ & 1023] * 2.0 - 1.0) * self.sizeY * 0.5;
      sz += (randomTable[randomIndex++ & 1023] * 2.0 - 1.0) * self.sizeZ * 0.5;
    } else if (self.shape == "sphere") {
      var r = randomTable[randomIndex++ & 1023] * self.sizeX * 0.5;
      var phi = randomTable[randomIndex++ & 1023] * 2 * pi;
      var theta = randomTable[randomIndex++ & 1023] * pi;
      var st = sin(theta);
      sx += r * st * cos(phi);
      sy += r * st * sin(phi);
      sz += r * cos(theta);
    }

    p.posX[i] = sx;
    p.posY[i] = sy;
    p.posZ[i] = sz;

    // --- Initialize from Type (Optimized with pre-calculated diffs) ---
    var life = type.lifeMin + type.lifeDiff * randomTable[randomIndex++ & 1023];
    p.life[i] = life;
    p.maxLife[i] = life;

    // Copy Feature Flags
    p.hasWiggle[i] = type.hasWiggle;
    p.hasGravity[i] = type.hasGravity;
    p.hasColorOverLife[i] = type.hasColorOverLife;
    p.hasAlphaOverLife[i] = type.hasAlphaOverLife;
    p.hasSizeOverLife[i] = type.hasSizeOverLife;
    p.hasRotation[i] = type.hasRotation;
    p.hasPhysics[i] = type.hasPhysics;

    var size = type.sizeMin + type.sizeDiff * randomTable[randomIndex++ & 1023];
    p.size[i] = size;
    p.baseSize[i] = size;
    p.diffSize[i] = type.sizeIncr * life;

    p.speed[i] = type.speedMin + type.speedDiff * randomTable[randomIndex++ & 1023];
    p.speedIncr[i] = type.speedIncr;
    p.speedWiggle[i] = type.speedWiggle;

    p.zSpeed[i] = type.zSpeedMin + type.zSpeedDiff * randomTable[randomIndex++ & 1023];
    p.zSpeedIncr[i] = type.zSpeedIncr;
    p.zSpeedWiggle[i] = type.zSpeedWiggle;

    var dir = type.dirMin + type.dirDiff * randomTable[randomIndex++ & 1023];
    p.direction[i] = dir;
    p.dirIncr[i] = type.dirIncr;
    p.dirWiggle[i] = type.dirWiggle;
    p.dirX[i] = cos(dir);
    p.dirY[i] = -sin(dir);

    p.velX[i] = 0;
    p.velY[i] = 0;
    p.velZ[i] = 0;

    p.sizeWiggle[i] = type.sizeWiggle;
    p.grav[i] = type.gravAmount;
    p.gravDir[i] = type.gravDir;
    p.gravX[i] = type.gravX;
    p.gravY[i] = type.gravY;
    p.zGrav[i] = type.zGravAmount;

    p.baseColorR[i] = type.colorStart[0];
    p.baseColorG[i] = type.colorStart[1];
    p.baseColorB[i] = type.colorStart[2];
    p.diffColorR[i] = type.colorEnd[0] - type.colorStart[0];
    p.diffColorG[i] = type.colorEnd[1] - type.colorStart[1];
    p.diffColorB[i] = type.colorEnd[2] - type.colorStart[2];
    p.colorR[i] = p.baseColorR[i];
    p.colorG[i] = p.baseColorG[i];
    p.colorB[i] = p.baseColorB[i];

    p.baseAlpha[i] = type.alphaStart;
    p.diffAlpha[i] = type.alphaEnd - type.alphaStart;
    p.alpha[i] = p.baseAlpha[i];

    p.rot[i] = type.rotMin + type.rotDiff * randomTable[randomIndex++ & 1023];
    p.rotIncr[i] = type.rotIncr;
    p.rotWiggle[i] = type.rotWiggle;

    return i;
  }

    /**
     * Updates the emitter logic and all its particles.
     */
    static update = function (dt) {
    gml_pragma("forceinline");

        // --- 0. Batch Random Generation (Static Table) ---
        static randomTableSize = 1024;
        static randomTable = undefined;
        static randomIndex = 0;
    if (randomTable == undefined) {
      randomTable = array_create(randomTableSize);
      for (var _r = 0; _r < randomTableSize; _r++) randomTable[_r] = random(2.0) - 1.0;
    }

    // 1. Emission
    if (self.enabled && self.streamType != undefined && self.streamRate > 0) {
      self._accumulator += dt * self.streamRate;
      while (self._accumulator >= 1) {
        self.spawn(self.streamType);
        self._accumulator--;
      }
    }

    // 2. Particle Lifecycle & Physics
    var p = self.pool;
    var count = p.aliveCount;
    if (count <= 0) return;

    var i = 0;
    var _active = p.activeIndices;

    // --- Array Reference Caching ---
    var _life = p.life;
    var _maxLife = p.maxLife;
    var _posX = p.posX;
    var _posY = p.posY;
    var _posZ = p.posZ;
    var _velX = p.velX;
    var _velY = p.velY;
    var _velZ = p.velZ;
    var _speed = p.speed;
    var _zSpeed = p.zSpeed;
    var _direction = p.direction;
    var _dirX = p.dirX;
    var _dirY = p.dirY;
    var _rot = p.rot;
    var _size = p.size;
    var _alpha = p.alpha;
    var _colorR = p.colorR;
    var _colorG = p.colorG;
    var _colorB = p.colorB;

    // Read-only arrays for interpolation
    var _baseSize = p.baseSize;
    var _diffSize = p.diffSize;
    var _baseAlpha = p.baseAlpha;
    var _diffAlpha = p.diffAlpha;
    var _baseColorR = p.baseColorR;
    var _diffColorR = p.diffColorR;
    var _baseColorG = p.baseColorG;
    var _diffColorG = p.diffColorG;
    var _baseColorB = p.baseColorB;
    var _diffColorB = p.diffColorB;

    // Physics/Incr arrays
    var _speedIncr = p.speedIncr;
    var _zSpeedIncr = p.zSpeedIncr;
    var _dirIncr = p.dirIncr;
    var _rotIncr = p.rotIncr;
    var _gravX = p.gravX;
    var _gravY = p.gravY;
    var _zGrav = p.zGrav;

    // Wiggle arrays
    var _speedWiggle = p.speedWiggle;
    var _zSpeedWiggle = p.zSpeedWiggle;
    var _dirWiggle = p.dirWiggle;
    var _rotWiggle = p.rotWiggle;
    var _sizeWiggle = p.sizeWiggle;

    // Flags
    var _fWiggle = p.hasWiggle;
    var _fPhysics = p.hasPhysics;
    var _fColor = p.hasColorOverLife;
    var _fAlpha = p.hasAlphaOverLife;
    var _fSize = p.hasSizeOverLife;
    var _fRot = p.hasRotation;

    while (i < count) {
      var idx = _active[i];

      // Life Update
      var life = _life[idx] - dt;
      if (life <= 0) {
        p.free(i);
        count--;
        continue;
      }
      _life[idx] = life;

      var nAge = 1.0 - (life / _maxLife[idx]); // Normalized age (0 to 1)

      // --- Physics & Movement ---
      if (_fPhysics[idx]) {
        _speed[idx] += _speedIncr[idx] * dt;
        _zSpeed[idx] += _zSpeedIncr[idx] * dt;

        var dir = _direction[idx];
        var dirIncr = _dirIncr[idx];

        // Wiggle (Batch Random)
        if (_fWiggle[idx]) {
          var r1 = randomTable[randomIndex++ & 1023];
          var r2 = randomTable[randomIndex++ & 1023];

          if (_speedWiggle[idx] != 0) _speed[idx] += r1 * _speedWiggle[idx] * dt;
          if (_zSpeedWiggle[idx] != 0) _zSpeed[idx] += r2 * _zSpeedWiggle[idx] * dt;
          if (_dirWiggle[idx] != 0) {
            dir += r1 * _dirWiggle[idx] * dt;
            _direction[idx] = dir;
            _dirX[idx] = cos(dir);
            _dirY[idx] = -sin(dir);
          }
          if (_rotWiggle[idx] != 0) _rot[idx] += r2 * _rotWiggle[idx] * dt;
        }

        if (dirIncr != 0) {
          dir += dirIncr * dt;
          _direction[idx] = dir;
          _dirX[idx] = cos(dir);
          _dirY[idx] = -sin(dir);
        }

        // Velocity & Gravity
        _velX[idx] += _gravX[idx] * dt;
        _velY[idx] += _gravY[idx] * dt;
        _velZ[idx] += _zGrav[idx] * dt;

        // Position
        _posX[idx] += (_dirX[idx] * _speed[idx] + _velX[idx]) * dt;
        _posY[idx] += (_dirY[idx] * _speed[idx] + _velY[idx]) * dt;
        _posZ[idx] += (_zSpeed[idx] + _velZ[idx]) * dt;
      } else {
        // Static movement if no complex physics
        _posX[idx] += _velX[idx] * dt;
        _posY[idx] += _velY[idx] * dt;
        _posZ[idx] += _velZ[idx] * dt;
      }

      // Rotation
      if (_fRot[idx]) {
        _rot[idx] += _rotIncr[idx] * dt;
      }

      // --- Visual Interpolation (Inline Lerp - Optimized with pre-calculated diffs) ---
      if (_fSize[idx]) {
        var size = _baseSize[idx] + _diffSize[idx] * nAge;
        if (_sizeWiggle[idx] != 0) size += randomTable[randomIndex++ & 1023] * _sizeWiggle[idx];
        _size[idx] = size;
      }

      if (_fAlpha[idx]) {
        _alpha[idx] = _baseAlpha[idx] + _diffAlpha[idx] * nAge;
      }

      if (_fColor[idx]) {
        _colorR[idx] = _baseColorR[idx] + _diffColorR[idx] * nAge;
        _colorG[idx] = _baseColorG[idx] + _diffColorG[idx] * nAge;
        _colorB[idx] = _baseColorB[idx] + _diffColorB[idx] * nAge;
      }

      i++;
    }
  }
}
