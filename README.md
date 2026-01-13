# Unique Particles 🚀
### Ultra-Performant 3D Particle Engine for GameMaker

Unique Particles is a state-of-the-art particle system that offloads 100% of particle simulation, physics, and visual interpolation to the GPU. By using **Circular Persistent Buffers** and a **Time-Based Simulation**, it achieves a near-zero CPU footprint even with tens of thousands of active particles.

---

## 📊 Performance Pillars

The engine is built on four core architectural pillars:

1. **Analytical GPU Trajectory**: The CPU never calculates positions. It only writes "Birth Data" (Spawn Time, Initial Velocity, etc.) to a buffer. The Vertex Shader solves the motion equation `p = p0 + v0*t + 0.5*a*t^2` in real-time.
2. **Circular Persistent Buffers**: Instead of rebuilding the vertex buffer every frame, the system uses a circular pool. For each particle, GML writes 6 vertices **only once** at spawn. From that point on, the GPU takes over.
3. **Zero-Allocation Memory Model**: Using a fixed-size `buffer_fixed` and pre-allocated arrays, the system performs **zero runtime allocations**. This eliminates the possibility of memory fragmentation or sudden GC spikes.
4. **Z-Up 3D Coordinate System**: Designed specifically for 3D GameMaker environments. All physics and billboarding logic assume a Z-Up coordinate system, making it perfect for modern 3D titles.
5. **Age-Based Auto-Discard**: There is no CPU-side "killing" of particles. The shader compares `uTime - spawnTime`. If it exceeds `maxLife`, the vertex is discarded (`gl_Position = vec4(0.0)`), resulting in zero processing for dead particles.
6. **Lightweight Vertex Layout (52 Bytes)**: To maximize bandwidth, we use a hybrid approach. Persistent per-particle data (Position, Velocity, Birth Time) is in the vertices, while shared emitter data (Gravity, Size/Color Transitions) is passed via **Uniforms**.

---

## 🧬 System Architecture

1. **[UeParticleType](scripts/UeParticleType/UeParticleType.gml)**: The template. Defines visuals, physics, and life ranges.
2. **[UeParticleEmitter](scripts/UeParticleEmitter/UeParticleEmitter.gml)**: The worker. Manages the **Circular Buffer** and decides *when* and *where* to spawn particles.
3. **[UeParticleRenderer](scripts/UeParticleRenderer/UeParticleRenderer.gml)**: The orchestrator. Manages the Vertex Format, Shaders, and Uniforms.
4. **[UeParticleSystem](scripts/UeParticleSystem/UeParticleSystem.gml)**: The manager. Handles LOD, Frustum Culling, and global updates.

---

## 🛠️ UeParticleType API

`UeParticleType` is the core of particle definition. It uses a fluent interface (method chaining) for clear and fast configuration.

### Configuration Methods

-   **`.setLife(min, max)`**: Lifetime in seconds.
-   **`.setSize(min, max, [incr], [wiggle])`**: Initial size and transformation over time.
-   **`.setSpeed(zMin, zMax, [xyMin], [xyMax], [zIncr], [xyIncr], [zWiggle], [xyWiggle])`**: Initial velocity and acceleration.
-   **`.setDirection(min, max, [incr], [wiggle])`**: Movement direction in degrees.
-   **`.setGravity(amountZ, [amountXY], [dirXY])`**: Constant gravity applied to particles.
-   **`.setColor(color1, [color2])`**: Start and end color (interpolation handled by GPU).
-   **`.setAlpha(alpha1, [alpha2])`**: Start and end transparency.
-   **`.setAdditive(bool)`**: Enables additive blend mode.
-   **`.setSprite(sprite, [subimg])`**: Uses a GameMaker sprite as a texture.
-   **`.setShape(name)`**: Uses a pre-defined procedural shape.

### 🎨 Procedural Shapes

The engine automatically generates procedural textures to avoid loading external sprites for common effects:

*   **`"point"`**: A solid circular point with slight antialiasing.
*   **`"sphere"`**: A soft particle with radial decay, perfect for smoke, glows, and fire.
*   **`"flare"`**: A cross-flare effect with a bright core, ideal for sparks.
*   **`"square"`**: A solid filled square.
*   **`"box"`**: A hollow square frame.
*   **`"disk"`**: A sharp, flat filled circle.
*   **`"ring"`**: A hollow circular ring with a thick border.

---

## 🚀 Quick Start

### 1. Simple Configuration
```gml
// Create the system
mySystem = new UeParticleSystem();

// Configure a fire type
fireType = new UeParticleType()
    .setLife(0.5, 1.2)
    .setSpeed(50, 150)
    .setGravity(20) // Z-up gravity
    .setColor(c_yellow, c_red)
    .setAlpha(1.0, 0.0)
    .setAdditive(true);
```

### 2. Multi-Emitter Setup
```gml
// 5000 particle max per emitter
myEmitter = mySystem.addEmitter(new UeParticleEmitter(5000));
myEmitter.region("box", -10, -10, 0, 10, 10, 5);
myEmitter.stream(fireType, 100); // 100 particles/sec
```

### 3. Loop
```gml
// Step Event (with Camera position for LOD)
mySystem.update(delta_time/1000000, camX, camY, camZ);

// Draw Event
mySystem.render(camera);
```

---

## 🌪️ Optimization Features

### Circular Write-Once Strategy
The system uses the `vertex_create_buffer_from_buffer` approach to push data from a raw CPU buffer to the GPU. This update only happens if a new particle was spawned, ensuring that static emitters cost **zero CPU** on the draw call.

### Analytical Frustum Culling
Instead of a simple bounding box, the system calculates a **Dynamic Culling Sphere**. The radius is determined analytically using the physical limits of the particle type:
`Radius = ShapeSize + (MaxSpeed * MaxLife + 0.5 * Gravity * MaxLife^2)`
This ensures 100% accurate visibility checks. The system then leverages GameMaker's native `sphere_is_visible` function, which is highly optimized and much faster than manual CPU-side frustum extraction and plane intersection.

### Soft Particles (Ground Fading)
To prevent ugly "sharp edges" when particles intersect with the ground (Z=0), the engine implements **GPU-side Ground Softness**.
The shader calculates the distance of each vertex from the ground plane and fades the alpha transparency accordingly. This creates a smooth, volumetric look for fire, smoke, and dust when hitting the floor.

### Distance LOD (Level of Detail)
Automatic emission scaling based on camera distance. Far emitters will automatically spawn fewer particles, significantly reducing overdraw and GPU fill-rate pressure without affecting the "volumetric feel" of the near-field scene.

---
Developed with ❤️ by Emmanuel Di Iorio - MIT License
