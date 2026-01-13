attribute vec3 in_Position;      // Center position
attribute vec4 in_Colour;        // Color + corner id bits (packed in R and B)
attribute vec2 in_TextureCoord;  // size, rotation
attribute vec3 in_Velocity;      // Instantaneous velocity (vx, vy, vz)

uniform vec3 u_ueCameraRight;
uniform vec3 u_ueCameraUp;
uniform vec4 u_ueUVRegion;       // [x, y, w, h]
uniform float u_ueTime;
uniform float u_ueInterpolation; // Time since last CPU update

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying float v_vSoftness;

void main() {
    // 1. Decode Corner ID from the LSB of R and B
    // R bit 0 (cid & 1), B bit 1 (cid >> 1)
    float rBits = mod(in_Colour.r * 255.0, 2.0);
    float bBits = mod(in_Colour.b * 255.0, 2.0);
    int cid = int(rBits + bBits * 2.0);

    // 2. Map cid to quad coordinates (-0.5 to 0.5)
    // 0: (-0.5, -0.5), 1: (0.5, -0.5), 2: (0.5, 0.5), 3: (-0.5, 0.5)
    vec2 corner;
    if (cid == 0)      corner = vec2(-0.5, -0.5);
    else if (cid == 1) corner = vec2( 0.5, -0.5);
    else if (cid == 2) corner = vec2( 0.5,  0.5);
    else               corner = vec2(-0.5,  0.5);

    // 3. Clean up color (remove the cid bits for clean rendering)
    v_vColour = vec4(
        floor(in_Colour.r * 255.0 / 2.0) * 2.0 / 255.0,
        in_Colour.g,
        floor(in_Colour.b * 255.0 / 2.0) * 2.0 / 255.0,
        in_Colour.a
    );

    // 4. UVs based on corner
    vec2 quadUV = corner + 0.5; // Maps to 0..1
    v_vTexcoord = u_ueUVRegion.xy + quadUV * u_ueUVRegion.zw;

    // 5. Billboard Expansion & Rotation
    float size = in_TextureCoord.x;
    float rot  = in_TextureCoord.y;
    float s = sin(rot);
    float c = cos(rot);
    
    vec2 rc = vec2(
        corner.x * c - corner.y * s,
        corner.x * s + corner.y * c
    );

	// Apply GPU Extrapolation
    vec3 animatedPos = in_Position + in_Velocity * u_ueInterpolation;

    vec3 worldPos = animatedPos + 
                   (u_ueCameraRight * rc.x + 
                    u_ueCameraUp    * rc.y) * size;

    // 6. Softness (Ground Fading)
    v_vSoftness = clamp(worldPos.z / (size * 0.5), 0.0, 1.0);

    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(worldPos, 1.0);
}
