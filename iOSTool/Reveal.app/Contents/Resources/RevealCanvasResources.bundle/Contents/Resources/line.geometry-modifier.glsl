//
//  Copyright © 2015 Itty Bitty Apps Pty Ltd. All rights reserved.
//

/** Input uniforms **/

// Approximate line width in points.
uniform float lineWidth = 1.0;

/** Utility functions **/

vec4 multiplyProj(mat4 matrix, vec4 vector)
{
    vec4 product = matrix * vector;
    return product / product.w;
}

#pragma body

/** Input data **/

// Vertex normals are reappropriated as tangent vectors; tangent is treated as "line direction" and must be the same across all vertices belonging to a line.
vec3 tangent = _geometry.normal;
// Texture coordinates of original geometry are used to derive line fraction of the vertex: U runs along the line, V runs across the line (along line extrusion).
// Derived line fraction is in [-0.5...0.5] range.
vec2 lineFraction = _geometry.texcoords[0] - 0.5;
// Original geometry is expected to be "flat lines", so vertex position is its position on the actual line.
vec4 linePoint = _geometry.position;
// To determine correct offsets, determine the line quad center (IMPORTANT: this assumes that quad length along the tangent is 1.0).
vec3 quadCenter = linePoint.xyz - tangent * lineFraction.x;

// Given the customized line width, viewport inverse resolution and "reference line height" (clip space line height for reference viewport height of 768 pixels), calculate stroke size for each axis. Using viewport resolution allows compensating for aspect ratio.
// Reference line height is multiplied by 2 here because NDC space coordinates are in [-1.0...1.0] range.
const float referenceLineHeight = 2.0/768.0;
// NOTE: u_inverseResolution is not directly documented as a uniform that can be used in a shader modifier, but it's mentioned in scn_metal header.
float inverseAspectRatio = u_inverseResolution.x / u_inverseResolution.y;
// Using a "reference height" is kinda cheating, but allows to avoid an extra uniform for viewport scale (Retina/non-Retina) and looks okay.
vec2 strokeSize = vec2(inverseAspectRatio, 1.0) * referenceLineHeight * lineWidth;

/** Transformations **/

// Project line point to NDC space.
vec4 linePointInClipSpace = u_modelViewProjectionTransform * linePoint;
vec4 linePointInNDCSpace = linePointInClipSpace / linePointInClipSpace.w;

// Project quad center to NDC space.
vec4 quadCenterInNDCSpace = multiplyProj(u_modelViewProjectionTransform, vec4(quadCenter, 1.0));

// Project tangent vector to NDC space in a form of offset to the quad center.
vec4 quadCenterWithOffsetInNDCSpace = multiplyProj(u_modelViewProjectionTransform, vec4(quadCenter + tangent, 1.0));
// Get back the tangent vector itself.
vec3 tangentInNDCSpace = normalize(quadCenterWithOffsetInNDCSpace.xyz - quadCenterInNDCSpace.xyz);

// Calculate "flat" (2D) tangent and binormal of the line in NDC space.
vec3 tangentFlat = normalize(vec3(tangentInNDCSpace.xy, 0.0));
vec3 binormalFlat = cross(tangentFlat, vec3(0.0, 0.0, -1.0));

// Calculate vertex "extrusion" (offset) in direction of binormal.
vec2 vertexExtrusion = binormalFlat.xy * lineFraction.y;
// Factor in stroke size based on viewport size.
vertexExtrusion *= strokeSize;

// Apply line extrusion to the line point in NDC space
vec4 vertexInNDCSpace = linePointInNDCSpace;
vertexInNDCSpace.xy += vertexExtrusion;
// Restore W coordinate of original projected vertex to correctly unproject it back.
vec4 extrudedVertex = vertexInNDCSpace * linePointInClipSpace.w;

// Calculate inverse projection transform (it's not provided by SceneKit on 10.11)
mat4 inverseProjectionTransform = u_modelViewTransform * u_inverseModelViewProjectionTransform;
// Unproject final vertex back to view space.
vec4 extrudedVertexInViewSpace = multiplyProj(inverseProjectionTransform, extrudedVertex);
// In view space, correct Z position of the extruded vertex to compensate for the rotation of the quad
vec4 linePointInViewSpace = multiplyProj(inverseProjectionTransform, linePointInClipSpace);
float offsetLengthInViewSpace = length(extrudedVertexInViewSpace.xy - linePointInViewSpace.xy);
extrudedVertexInViewSpace.z = linePointInViewSpace.z + offsetLengthInViewSpace;

// Finally, unproject the compensated vertex from view space back to model space.
_geometry.position = multiplyProj(u_inverseModelViewTransform, extrudedVertexInViewSpace);
