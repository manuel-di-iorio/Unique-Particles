/** 
* @description Ultra-performance SoA pool for GPU-simulated particles. 
* Stores birth data (Initial position, velocity, etc.) to offload all physics to the shader.
*/
function UeParticlePool(maxCount) constructor {
  gml_pragma("forceinline");
  self.maxCount = maxCount;
  self.aliveCount = 0;

  // --- SoA Arrays (Birth Data) ---
  self.spawnX = array_create(maxCount, 0);
  self.spawnY = array_create(maxCount, 0);
  self.spawnZ = array_create(maxCount, 0);
  
  self.initVelX = array_create(maxCount, 0);
  self.initVelY = array_create(maxCount, 0);
  self.initVelZ = array_create(maxCount, 0);
  
  self.gravityX = array_create(maxCount, 0);
  self.gravityY = array_create(maxCount, 0);
  self.gravityZ = array_create(maxCount, 0);
  
  // Normalized 0..1 age is calculated as (maxLife - life) / maxLife
  self.life = array_create(maxCount, 0);
  self.maxLife = array_create(maxCount, 0);
  
  self.sizeStart = array_create(maxCount, 0);
  self.sizeEnd = array_create(maxCount, 0);
  
  self.colorStart = array_create(maxCount, 0); // 32bit BGRA
  self.colorEnd = array_create(maxCount, 0);   // 32bit BGRA
  
  self.rotStart = array_create(maxCount, 0);
  self.rotSpeed = array_create(maxCount, 0);
  
  self.seed = array_create(maxCount, 0); // Random value for variety in shader

  // --- Active/Free List (Zero Allocations Runtime) ---
  self.activeIndices = array_create(maxCount, 0);
  self.freeIndices = array_create(maxCount, 0);
  self.freeCount = maxCount;

  // Initialize free list
  for (var i = 0; i < maxCount; i++) self.freeIndices[i] = i;

  /** 
  * Allocate a new particle slot 
  */ 
  static allocate = function () {
    gml_pragma("forceinline");
    if (self.freeCount == 0) return -1;
    var idx = self.freeIndices[--self.freeCount];
    self.activeIndices[self.aliveCount++] = idx;
    return idx;
  }

  /**
  * Free a particle slot using swap-remove
  */
  static free = function (activeIndex) {
    gml_pragma("forceinline");
    var realIdx = self.activeIndices[activeIndex];
    self.freeIndices[self.freeCount++] = realIdx;
    self.aliveCount--;
    self.activeIndices[activeIndex] = self.activeIndices[self.aliveCount];
  }
  
  /**
  * Optional: Batch kill by life (Called by Emitter)
  */
  static updateLife = function(dt) {
    gml_pragma("forceinline");
    var count = self.aliveCount;
    var active = self.activeIndices;
    var lifeArr = self.life;
    var i = 0;
    while (i < count) {
        var idx = active[i];
        lifeArr[idx] -= dt;
        if (lifeArr[idx] <= 0) {
            // Free it
            self.freeIndices[self.freeCount++] = idx;
            count--;
            active[i] = active[count];
        } else {
            i++;
        }
    }
    self.aliveCount = count;
  }
}
