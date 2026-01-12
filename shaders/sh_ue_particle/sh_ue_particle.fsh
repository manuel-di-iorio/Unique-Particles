varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying float v_vSoftness;

uniform float u_ueTime;

void main() {
    if (v_vSoftness < 0.005) discard;
    
    vec4 texColor = texture2D(gm_BaseTexture, v_vTexcoord);
    
    vec4 finalColor = v_vColour * texColor;
    finalColor.a *= v_vSoftness; // Apply ground fading
    
    gl_FragColor = finalColor;
}
