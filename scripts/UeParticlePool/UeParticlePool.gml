/** 
* @description Data-oriented container for particles. 
* Stores particle properties in separate arrays (SoA) for better performance in GML. 
*/
function UeParticlePool(maxCount) constructor {
  gml_pragma("forceinline");
  self.maxCount = maxCount;
  self.aliveCount = 0;

  // Fixed arrays for performance (no dynamic attributes) 
  self.posX = array_create(maxCount, 0);
  self.posY = array_create(maxCount, 0);
  self.posZ = array_create(maxCount, 0);

  self.velX = array_create(maxCount, 0);
  self.velY = array_create(maxCount, 0);
  self.velZ = array_create(maxCount, 0);

  self.colorR = array_create(maxCount, 1.0);
  self.colorG = array_create(maxCount, 1.0);
  self.colorB = array_create(maxCount, 1.0);
  self.alpha = array_create(maxCount, 1.0);
  self.size = array_create(maxCount, 1.0);
  self.rot = array_create(maxCount, 0);
  self.rotIncr = array_create(maxCount, 0);
  self.rotWiggle = array_create(maxCount, 0);
  self.life = array_create(maxCount, 0);
  self.maxLife = array_create(maxCount, 0);

  // Base properties (for Over Life calculations) 
  self.baseSize = array_create(maxCount, 1.0);
  self.baseAlpha = array_create(maxCount, 1.0);
  self.baseColorR = array_create(maxCount, 1.0);
  self.baseColorG = array_create(maxCount, 1.0);
  self.baseColorB = array_create(maxCount, 1.0);

  // Diffs for interpolation (saves one subtraction in update loop) 
  self.diffSize = array_create(maxCount, 0);
  self.diffAlpha = array_create(maxCount, 0);
  self.diffColorR = array_create(maxCount, 0);
  self.diffColorG = array_create(maxCount, 0);
  self.diffColorB = array_create(maxCount, 0);

  // Speed/Direction for easier movement updates 
  self.speed = array_create(maxCount, 0);
  self.direction = array_create(maxCount, 0);
  self.speedIncr = array_create(maxCount, 0);
  self.speedWiggle = array_create(maxCount, 0);
  self.zSpeed = array_create(maxCount, 0);
  self.zSpeedIncr = array_create(maxCount, 0);
  self.zSpeedWiggle = array_create(maxCount, 0);
  self.dirIncr = array_create(maxCount, 0);
  self.dirWiggle = array_create(maxCount, 0);
  self.dirX = array_create(maxCount, 1.0);
  self.dirY = array_create(maxCount, 0.0);
  self.sizeWiggle = array_create(maxCount, 0);
  self.grav = array_create(maxCount, 0);
  self.gravDir = array_create(maxCount, 270);
  self.gravX = array_create(maxCount, 0);
  self.gravY = array_create(maxCount, 0);
  self.zGrav = array_create(maxCount, 0);

  // Feature Flags per-particle (copied from UeParticleType) 
  self.hasWiggle = array_create(maxCount, false);
  self.hasGravity = array_create(maxCount, false);
  self.hasColorOverLife = array_create(maxCount, false);
  self.hasAlphaOverLife = array_create(maxCount, false);
  self.hasSizeOverLife = array_create(maxCount, false);
  self.hasRotation = array_create(maxCount, false);
  self.hasPhysics = array_create(maxCount, false);

  // ===== FREE LIST APPROACH ===== 
  // Instead of swap, we use an array of active indices 
  self.activeIndices = array_create(maxCount, 0);
  self.freeIndices = array_create(maxCount, 0);
  self.freeCount = maxCount;

  // Initialize free list 
  for (var i = 0; i < maxCount; i++) {
    self.freeIndices[i] = i;
  }

  /** 
  * Allocate a new particle slot from the free list 
  */ 
  static allocate = function () {
    gml_pragma("forceinline");
    if (self.freeCount == 0) return -1;

    var idx = self.freeIndices[--self.freeCount];
    self.activeIndices[self.aliveCount++] = idx;

    return idx;
  }

  /**
  * Frees up a particle slot (much faster than swapping!)
  */
  static free = function (activeIndex) {
    gml_pragma("forceinline");

    // Get the real index from the active list
    var realIdx = self.activeIndices[activeIndex];

    // Put back into the free list
    self.freeIndices[self.freeCount++] = realIdx;

    // Remove from the active list (swap only the index array!)
    self.aliveCount--;
    self.activeIndices[activeIndex] = self.activeIndices[self.aliveCount];
  }

  /** 
  * Get the real index of an active particle 
  */ 
  static getIndex = function (activeIndex) {
    gml_pragma("forceinline");
    return self.activeIndices[activeIndex];
  }

  /**
   * Sort particles back-to-front based on distance to a point (usually camera)
   */
  static depthSort = function(_camX, _camY, _camZ) {
    var _count = self.aliveCount;
    if (_count <= 1) return;
    
    // Ensure the size of the global distance array
    if (array_length(global.__ue_sort_dist) < self.maxCount) {
        global.__ue_sort_dist = array_create(self.maxCount, 0);
    }
    
    // Shared temp array for indices to avoid per-frame allocation
    if (array_length(global.__ue_sort_indices) < _count) {
        global.__ue_sort_indices = array_create(self.maxCount, 0);
    }
    
    var _active = self.activeIndices;
    var _px = self.posX;
    var _py = self.posY;
    var _pz = self.posZ;
    var _dists = global.__ue_sort_dist;
    var _indices = global.__ue_sort_indices;
    
    for (var i = 0; i < _count; i++) {
        var _idx = _active[i];
        var _dx = _px[_idx] - _camX;
        var _dy = _py[_idx] - _camY;
        var _dz = _pz[_idx] - _camZ;
        _dists[_idx] = _dx*_dx + _dy*_dy + _dz*_dz;
        _indices[i] = _idx;
    }
    
    // Sort the temporary index list using a resized global array to avoid allocation
    var _subset = global.__ue_sort_subset;
    array_resize(_subset, _count);
    array_copy(_subset, 0, _indices, 0, _count);
    
    array_sort(_subset, function(_a, _b) {
        gml_pragma("forceinline");
        return global.__ue_sort_dist[_b] - global.__ue_sort_dist[_a];
    });
    
    // Copy back to activeIndices (the first 'count' elements)
    array_copy(_active, 0, _subset, 0, _count);
  }
}

global.__ue_sort_dist = array_create(8192, 0);
global.__ue_sort_indices = array_create(8192, 0);
global.__ue_sort_subset = array_create(8192, 0);
