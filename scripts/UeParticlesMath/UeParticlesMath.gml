/**
* @description Math utilities for Unique Particles.
*/

global.UeTrigLUTSize = 2048;
global.UeTrigLUT_Sin = array_create(global.UeTrigLUTSize);
global.UeTrigLUT_Cos = array_create(global.UeTrigLUTSize);
global.UeTrigLUT_Step = global.UeTrigLUTSize / (2 * pi);

for (var i = 0; i < global.UeTrigLUTSize; i++) {
    var _angle = (i / global.UeTrigLUTSize) * 2 * pi;
    global.UeTrigLUT_Sin[i] = sin(_angle);
    global.UeTrigLUT_Cos[i] = cos(_angle);
}

/**
* Fast sine using LUT. Angle in radians.
*/
function fast_sin(_rad) {
    gml_pragma("forceinline");
    var _idx = floor((_rad * global.UeTrigLUT_Step) % global.UeTrigLUTSize);
    if (_idx < 0) _idx += global.UeTrigLUTSize;
    return global.UeTrigLUT_Sin[_idx];
}

/**
* Fast cosine using LUT. Angle in radians.
*/
function fast_cos(_rad) {
    gml_pragma("forceinline");
    var _idx = floor((_rad * global.UeTrigLUT_Step) % global.UeTrigLUTSize);
    if (_idx < 0) _idx += global.UeTrigLUTSize;
    return global.UeTrigLUT_Cos[_idx];
}
