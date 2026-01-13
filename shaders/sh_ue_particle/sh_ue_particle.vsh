attribute vec3 in_Position;      // SpawnPos
attribute vec4 in_Colour;        // ColorStart (U8x4)
attribute vec2 in_TextureCoord;  // CornerXY (-0.5 a 0.5)
attribute vec4 in_TextureCoord1; // x: vX, y: vY, z: vZ, w: spawnTime
attribute vec3 in_TextureCoord2; // x: maxLife, y: sStart, z: rStart

// Uniforms (Costanti per emitter)
uniform vec3 u_ueCameraRight;
uniform vec3 u_ueCameraUp;
uniform vec4 u_ueUVRegion;
uniform float u_ueTime;

uniform vec3 u_ueGravity;
uniform float u_ueSizeEnd;
uniform vec4 u_ueColorEnd;
uniform float u_ueRotSpeed;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying float v_vSoftness;

void main() {
    float age = u_ueTime - in_TextureCoord1.w;
    float maxLife = in_TextureCoord2.x;
    
    // Auto-discard se morta (spostiamo fuori dal frustum)
    if (age < 0.0 || age > maxLife) {
        gl_Position = vec4(0.0);
        return;
    }

    float t = age / maxLife;

    // 1. Fisica (Uniform Gravity)
    vec3 basePos = in_Position + (in_TextureCoord1.xyz * age) + (0.5 * u_ueGravity * age * age);

    // 2. Visuals (Uniform Transitions)
    float size = mix(in_TextureCoord2.y, u_ueSizeEnd, t);
    float rot  = in_TextureCoord2.z + (u_ueRotSpeed * age);
    v_vColour  = mix(in_Colour, u_ueColorEnd, t);

    // 3. Billboard
    float s = sin(rot); float c = cos(rot);
    vec2 rotatedCorner = vec2(in_TextureCoord.x * c - in_TextureCoord.y * s, in_TextureCoord.x * s + in_TextureCoord.y * c);
    vec3 worldPos = basePos + (u_ueCameraRight * rotatedCorner.x + u_ueCameraUp * rotatedCorner.y) * size;

    // 4. Output
    v_vSoftness = clamp(worldPos.z / (size * 0.5), 0.0, 1.0);
    v_vTexcoord = u_ueUVRegion.xy + (in_TextureCoord + 0.5) * u_ueUVRegion.zw;
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(worldPos, 1.0);
}
