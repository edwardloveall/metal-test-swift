import simd
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
  let device: MTLDevice
  let pipelineState: MTLRenderPipelineState
  let commandQueue: MTLCommandQueue
  var viewportSize = vector_uint2(0, 0)

  init(mtkView: MTKView) {
    guard
      let _device = mtkView.device,
      let _queue = _device.makeCommandQueue()
    else {
      fatalError("could not set up metal")
    }
    device = _device
    commandQueue = _queue

    guard
      let defaultLibrary = device.makeDefaultLibrary(),
      let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader"),
      let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
    else {
      fatalError("could not set up vertex and fragment shaders")
    }

    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Simple Pipeline"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

    do {
      try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch {
      fatalError("could not create pipeline state")
    }
  }

  func draw(in view: MTKView) {
    guard
      let currentDrawable = view.currentDrawable,
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    else {
      return
    }

    let triangleVertices: [Vertex] = [
      Vertex(position: vector_float2(250, -250), color: vector_float4(1, 0, 0, 1)),
      Vertex(position: vector_float2(-250, -250), color: vector_float4(0, 1, 0, 1)),
      Vertex(position: vector_float2(0, 250), color: vector_float4(0, 0, 1, 1))
    ]

    commandBuffer.label = "MyCommand"
    renderEncoder.label = "MyRenderEncoder"

    view.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    let viewport = MTLViewport(
      originX: 0,
      originY: 0,
      width: Double(viewportSize.x),
      height: Double(viewportSize.y),
      znear: -1,
      zfar: 1
    )
    renderEncoder.setViewport(viewport)
    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setVertexBytes(
      triangleVertices,
      length: MemoryLayout<Vertex>.size * triangleVertices.count,
      index: Int(VertexInputIndexVertices.rawValue)
    )
    renderEncoder.setVertexBytes(
      &viewportSize,
      length: MemoryLayout.size(ofValue: viewportSize),
      index: Int(VertexInputIndexViewportSize.rawValue)
    )
    renderEncoder.drawPrimitives(
      type: MTLPrimitiveType.triangle,
      vertexStart: 0,
      vertexCount: triangleVertices.count
    )

    renderEncoder.endEncoding()

    commandBuffer.present(currentDrawable)
    commandBuffer.commit()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    viewportSize.x = UInt32(size.width)
    viewportSize.y = UInt32(size.height)
  }
}
