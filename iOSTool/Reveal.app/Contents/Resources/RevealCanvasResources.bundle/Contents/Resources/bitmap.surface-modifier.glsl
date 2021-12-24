//
//  Copyright © 2016 Itty Bitty Apps Pty Ltd. All rights reserved.
//

#pragma transparent
#pragma body

/** Darkening effect */

// Multiply.red component is used as darkening intensity
_surface.diffuse.rgb *= _surface.multiply.r;

/** Desaturation effect */

float colorLuminance = dot(_surface.diffuse.rgb, vec3(0.222, 0.707, 0.071));
vec3 desaturatedColor = vec3(colorLuminance);

// Multiply.green component is used as inverse desaturation intensity
_surface.diffuse.rgb = mix(desaturatedColor, _surface.diffuse.rgb, _surface.multiply.g);

/** Transparency effect */

// Transparent property is usually applied last - to make sure that tinting is not affected by it, apply it first instead
_surface.diffuse *= _surface.transparent.a;

/** Tinting effect */

// Emission property is used as tint color and blend factor
vec4 srcColor = _surface.emission;
vec4 dstColor = _surface.diffuse;

// Blend RGB with a classic "SRC_ALPHA / ONE_MINUS_SRC_ALPHA" formula
vec3 outRGB = srcColor.rgb * srcColor.a + dstColor.rgb * (1.0 - srcColor.a);
// Blend Alpha component by modulating DST_ALPHA with SRC_ALPHA
float outAlpha = srcColor.a + dstColor.a * (1.0 - srcColor.a);

_surface.diffuse = vec4(outRGB, outAlpha);

// Finally, clear Multiply, Transparent and Emission surface properties used for the custom effects to disable their default effect on the fragment color
_surface.multiply = vec4(1.0);
_surface.transparent = vec4(1.0);
_surface.emission = vec4(0.0);
