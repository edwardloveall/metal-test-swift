#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
#import "MetalTypes.h"

typedef struct {
  float4 clipSpacePosition [[position]];
  float2 textureCoordinate;
} RasterizerData;

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             device Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(VertexInputIndexViewportSize)]]) {
  RasterizerData out;

  out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
  float2 pixelSpacePosition = vertices[vertexID].position.xy;
  float2 viewportSize = float2(*viewportSizePointer);
  out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
  out.clipSpacePosition.z = 0.0;
  out.clipSpacePosition.w = 1.0;
  out.textureCoordinate = vertices[vertexID].textureCoordinate;

  return out;
}

fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[texture(TextureIndexBaseColor)]]) {
  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
  return float4(colorSample);
}
