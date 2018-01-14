#ifndef MetalTypes_h
#define MetalTypes_h

#include <simd/simd.h>

typedef struct {
  vector_float2 position;
  vector_float4 color;
} Vertex;

typedef enum VertexInputIndex {
  VertexInputIndexVertices = 0,
  VertexInputIndexViewportSize = 1,
} VertexInputIndex;

#endif
