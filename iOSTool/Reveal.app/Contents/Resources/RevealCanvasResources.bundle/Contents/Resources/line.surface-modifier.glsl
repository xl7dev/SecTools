//
//  Copyright © 2015 Itty Bitty Apps Pty Ltd. All rights reserved.
//

/** Input uniforms **/

// Line dashing factor: 0 for no dashing, 1 for "- ", 2 for "- - ", 2.5 for "- - -" and so on.
uniform float lineDashFactor;

#pragma transparent
#pragma body

// Texture coordinates of original geometry are used to derive line fraction.
// IMPORTANT: always reference the texture coordinates in the fragment shader (even just in a comment) to force SceneKit to include them in vertex data (otherwise it would optimize them out).
// IMPORTANT: do NOT reference .diffuseTexcoord - this would signal SceneKit (10.12) to treat diffuse property as a texture instead of a solid color. Use ambient instead, as it's not used anyway.
vec2 lineFraction = _surface.ambientTexcoord;

/** Line dashing **/

float dashPhase = fract(lineFraction.x * lineDashFactor);
_surface.diffuse *= step(0.5, 1.0 - dashPhase);
