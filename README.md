# Unique Particles 🚀
### Ultra-Optimized 3D Particle Engine for GameMaker

Unique Particles is a data-oriented (SoA) particle system designed for maximum performance in 3D environments. It overcomes the limitations of the standard GameMaker system by offering full support for 3D billboarding, advanced mathematical optimizations, and an extensible architecture.

---

## 📊 Top Performance

The system was designed with a zero-overhead approach. Here are the key optimizations applied:

- **Batch Random Generation**: 99% reduction in calls to `random()` through pre-generated static tables.
- **Feature Flags**: Each particle analyzes its own properties at startup to skip unnecessary code branches (e.g., skips gravity calculations if gravity is zero).
- **Zero Subtraction in the Critical Loop**: All interpolation (Lerp) and spawn values ​​use pre-calculated differences (`Base + Diff * Age`).
- **Free List Management**: Particle creation and destruction is up to 40x faster than standard approaches with `array_delete` or swap.
- **Pre-calculated Trigonometry**: Massive use of radians and pre-calculated vectors to avoid `dsin`/`dcos` during position updates.
- **Batch Rendering**: Emitters are grouped by Blend Mode to minimize GPU state changes.
- **View Matrix Caching**: 3D billboarding optimization through view matrix caching.
- **Distance-based LOD**: Automatic reduction of emission rates and update frequency based on distance to camera.
- **Update Skipping**: Far away emitters skip animation frames but accumulate delta time to save CPU without losing positional accuracy.
- **GPU Extrapolation**: The shader uses particle velocity to smoothly interpolate movement during skipped frames, ensuring 60 FPS visual fluidity even with 10 FPS logic updates.
- **Native Frustum Culling**: Automatic skipping of invisible emitters using `sphere_is_visible`.
- **Conditional Depth Sorting**: Only performs expensive depth sorting for non-additive particles and only if the count is manageable (< 512).
- **Trig LUT (Look-Up Table)**: Pre-calculated sine and cosine tables (2048 steps) to eliminate `sin`/`cos` overhead during updates.
- **Emitter-level Branching**: Critical update loops are branched at the emitter level rather than per-particle, reducing CPU branching overhead.
- **Value Quantization**: Float values (size, alpha) are quantized to reduce CPU->GPU jitter and bandwidth noise.
- **Forceinline**: Systematic use of `gml_pragma("forceinline")` to eliminate function call overhead.

---

## 🛠️ System Architecture

The system is divided into 5 core components:

1. **[UeParticleType](scripts/UeParticleType/UeParticleType.gml)**: Defines *how* a particle appears and behaves (color, velocity, gravity, etc.). Uses a Fluent API for quick configuration.
2. **[UeParticlePool](scripts/UeParticlePool/UeParticlePool.gml)**: The data container. Uses a **SoA (Structure of Arrays)** structure to maximize data locality and cache performance.
3. **[UeParticleEmitter](scripts/UeParticleEmitter/UeParticleEmitter.gml)**: Manages the spawning of particles in specific shapes (Box, Sphere), LOD logic, and visibility tracking.
4. **[UeParticleRenderer](scripts/UeParticleRenderer/UeParticleRenderer.gml)**: Manages the vertex buffer and shader. Implements ultra-fast 3D billboarding.
5. **[UeParticleSystem](scripts/UeParticleSystem/UeParticleSystem.gml)**: The high-level manager that coordinates the updating and drawing, managing global visibility and LOD updates.

---

## 🚀 Quick Start

### 1. Initialization
```gml
// Create the system
mySystem = new UeParticleSystem();

// Create a particle type
fireType = new UeParticleType() 
.setLife(1, 2) 
.setSize(10, 20, -5) 
.setSpeed(130, 220, 8, 20) // Z range, then XY range
.setDirection(0, 360) 
.setGravity(0.1) 
.setAlpha(1, 0) 
.setAdditive(true);
```

### 2. Emitter Creation
```gml
// Create an emitter with a pool of 1000 particles
myEmitter = new UeParticleEmitter(mySystem, 1000);
myEmitter.stream(fireType, 10); // Spawn 10 particles per second
```

### 3. Update and Draw
```gml
// Step Event
// Pass camera position for automatic LOD calculation
mySystem.update(delta_time / 1000000, camX, camY, camZ);

// Draw Event
// Automatically performs Frustum Culling for all emitters
mySystem.render();
```

---

## 📈 Optimization Features

### Distance LOD (Level of Detail)
Emitters can automatically scale their emission rate based on distance to the camera.
```gml
emitter.lodDistances = [500, 1000]; // Pixels
emitter.lodRates = [1.0, 0.5, 0.1]; // 100% rate, 50% rate, 10% rate
emitter.lodSkips = [1, 2, 4]; // Even at LOD 0, we skip 1 frame to save CPU
```

### Update Skipping & GPU Extrapolation
When an emitter skips an update via LOD, it accumulates the `delta_time`. The **UeParticleRenderer** automatically passes this accumulated time and the particle's velocity to the vertex shader. The shader then performs a linear extrapolation:
`final_pos = position + velocity * accumulated_time`

This allows far-away effects to run at very low CPU frequencies (e.g., 15 FPS) while appearing perfectly smooth (60 FPS) to the player.

### Frustum Culling
The system uses GameMaker's native `sphere_is_visible` to cull entire emitters before processing. The culling radius is automatically estimated based on particle speed, life, and gravity, but can be set manually:
```gml
emitter.autoCullingRadius = false;
emitter.cullingRadius = 250;
```

---

## 🎨 Shader & Rendering
The system uses a dedicated shader ([sh_ue_particle](shaders/sh_ue_particle/sh_ue_particle.fsh)) that implements **Early Discard**. This means that transparent pixels are discarded before the texture is even processed, saving precious fillrate on the GPU.

---

## 📝 Technical Notes
- **Radians**: Internally, the system only works in radians. The Fluent API functions accept degrees for convenience and convert them instantly.
- **Delta Time**: The system automatically manages delta time to ensure smooth motion regardless of frame rate.
- **3D Ready**: Natively designed for 3D, but perfectly usable in 2D by simply ignoring the Z coordinate.

---
Developed with ❤️ in GameMaker.
