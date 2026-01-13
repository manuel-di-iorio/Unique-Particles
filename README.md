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
- **Forceinline**: Systematic use of `gml_pragma("forceinline")` to eliminate function call overhead.

---

## 🛠️ System Architecture

The system is divided into 5 core components:

1. **[UeParticleType](scripts/UeParticleType/UeParticleType.gml)**: Defines *how* a particle appears and behaves (color, velocity, gravity, etc.). Uses a Fluent API for quick configuration.
2. **[UeParticlePool](scripts/UeParticlePool/UeParticlePool.gml)**: The data container. Uses a **SoA (Structure of Arrays)** structure to maximize data locality and cache performance.
3. **[UeParticleEmitter](scripts/UeParticleEmitter/UeParticleEmitter.gml)**: Manages the spawning of particles in specific shapes (Box, Sphere) and the updating of their logic.
4. **[UeParticleRenderer](scripts/UeParticleRenderer/UeParticleRenderer.gml)**: Manages the vertex buffer and shader. Implements ultra-fast 3D billboarding.
5. **[UeParticleSystem](scripts/UeParticleSystem/UeParticleSystem.gml)**: The high-level manager that coordinates the updating and drawing of multiple emitters.

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
mySystem.update();

// Draw Event (or Draw GUI)
mySystem.render();
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
