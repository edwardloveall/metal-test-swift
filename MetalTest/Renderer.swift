import simd
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
  let device: MTLDevice
  var pipelineState: MTLRenderPipelineState?
  let commandQueue: MTLCommandQueue
  var viewportSize = vector_uint2(0, 0)
  var vertexBuffer: MTLBuffer?
  var vertexCount: NSInteger = 0

  init(mtkView: MTKView) {
    guard
      let _device = mtkView.device,
      let _queue = _device.makeCommandQueue()
    else {
      fatalError("could not set up metal")
    }
    device = _device
    commandQueue = _queue
    super.init()
    self.loadMetal(mtkView: mtkView)
  }

  func generatedVertexData() -> NSMutableData {
    let quadVertices: [Vertex] = [
      Vertex(position: vector_float2(-20, 20), color: vector_float4(1, 0, 0, 1)),
      Vertex(position: vector_float2(20, 20), color: vector_float4(0, 0, 1, 1)),
      Vertex(position: vector_float2(-20, -20), color: vector_float4(0, 1, 0, 1)),
      Vertex(position: vector_float2(20, -20), color: vector_float4(1, 0, 0, 1)),
      Vertex(position: vector_float2(-20, -20), color: vector_float4(0, 1, 0, 1)),
      Vertex(position: vector_float2(20, 20), color: vector_float4(0, 0, 1, 1)),
    ]
    let columns: NSInteger = 25
    let rows: NSInteger = 15
    let vertsPerQuad: NSInteger = quadVertices.count
    let quadSpacing: Float = 50.0
    let vertexSize = MemoryLayout<Vertex>.size

    let dataSize = vertexSize * vertsPerQuad * columns * rows
    guard
      let vertexData = NSMutableData(capacity: dataSize)
    else {
      fatalError("could not create data container")
    }

    for row in (0..<rows) {
      for column in (0..<columns) {
        let quadOffset = quadSpacing / 2.0
        let columnStart = Float(-columns) / 2.0
        let rowStart = Float(-rows) / 2.0
        let x = (columnStart + Float(column)) * quadSpacing + quadOffset
        let y = (rowStart + Float(row)) * quadSpacing + quadOffset
        let upperLeftPosition = vector_float2(x, y)

        for quadVertex in quadVertices {
          let newPosition = quadVertex.position + upperLeftPosition
          var vertex = Vertex(position: newPosition, color: quadVertex.color)

          vertexData.append(&vertex, length: vertexSize)
        }
      }
    }
    return vertexData
  }

  func loadMetal(mtkView: MTKView) {
    mtkView.colorPixelFormat = .bgra8Unorm_srgb

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

    let vertexData = generatedVertexData()
    vertexBuffer = device.makeBuffer(
      bytes: vertexData.bytes,
      length: vertexData.length,
      options: .storageModeShared
    )
    vertexCount = vertexData.length / MemoryLayout<Vertex>.size
  }

  func draw(in view: MTKView) {
    guard
      let currentDrawable = view.currentDrawable,
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
      let pipelineState = pipelineState
    else {
      fatalError()
    }

    commandBuffer.label = "MyCommand"
    renderEncoder.label = "MyRenderEncoder"

    view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
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
    renderEncoder.setVertexBuffer(
      vertexBuffer,
      offset: 0,
      index: Int(VertexInputIndexVertices.rawValue)
    )

    renderEncoder.setVertexBytes(
      &viewportSize,
      length: MemoryLayout.size(ofValue: viewportSize),
      index: Int(VertexInputIndexViewportSize.rawValue)
    )

    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: vertexCount
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
