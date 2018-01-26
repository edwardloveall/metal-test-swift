import simd
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
  let device: MTLDevice
  var pipelineState: MTLRenderPipelineState?
  let commandQueue: MTLCommandQueue
  let texture: MTLTexture
  var vertexBuffer: MTLBuffer?
  var vertexCount: NSInteger = 0
  var viewportSize = vector_uint2(0, 0)

  init(mtkView: MTKView) {
    guard
      let device = mtkView.device,
      let queue = device.makeCommandQueue()
    else {
      fatalError("could not set up metal")
    }
    self.device = device
    self.commandQueue = queue
    guard
      let imageLocation = Bundle.main.url(forResource: "Earth", withExtension: "tga"),
      let image = TGAImage(location: imageLocation)
    else {
      fatalError("An valid Image.tga file is needed to load into a texture")
    }
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.width = image.width
    textureDescriptor.height = image.height

    guard
      let texture = device.makeTexture(descriptor: textureDescriptor)
    else {
      fatalError("Could not make a texture from the MTLTextureDescriptor")
    }
    self.texture = texture
    let bytesPerRow = MemoryLayout<UInt32>.size * image.width
    let origin = MTLOrigin(x: 0, y: 0, z: 0)
    let size = MTLSize(width: image.width, height: image.height, depth: 1)
    let region = MTLRegion(origin: origin, size: size)
    var pixelData = image.normalizedData()

    texture.replace(region: region,
                    mipmapLevel: 0,
                    withBytes: &pixelData,
                    bytesPerRow: bytesPerRow)
    super.init()
    self.loadMetal(mtkView: mtkView)
  }

  func loadMetal(mtkView: MTKView) {
    let vertexData = generatedVertexData()
    vertexBuffer = device.makeBuffer(
      bytes: vertexData.bytes,
      length: vertexData.length,
      options: .storageModeShared
    )
    vertexCount = vertexData.length / MemoryLayout<Vertex>.size

    guard
      let defaultLibrary = device.makeDefaultLibrary(),
      let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader"),
      let fragmentFunction = defaultLibrary.makeFunction(name: "samplingShader")
    else {
      fatalError("could not set up vertex and fragment shaders")
    }

    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.label = "Texturing Pipeline"
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

    do {
      try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch {
      fatalError("could not create pipeline state")
    }
  }

  func generatedVertexData() -> NSMutableData {
    let quadVertices: [Vertex] = [
      Vertex(position: vector_float2(250, -250), textureCoordinate: vector_float2(1, 0)),
      Vertex(position: vector_float2(-250, -250), textureCoordinate: vector_float2(0, 0)),
      Vertex(position: vector_float2(-250, 250), textureCoordinate: vector_float2(0, 1)),
      Vertex(position: vector_float2(250, -250), textureCoordinate: vector_float2(1, 0)),
      Vertex(position: vector_float2(-250, 250), textureCoordinate: vector_float2(0, 1)),
      Vertex(position: vector_float2(250, 250), textureCoordinate: vector_float2(1, 1))
    ]

    let vertexData = NSMutableData()
    let vertexSize = MemoryLayout<Vertex>.size
    for var vertex in quadVertices {
      vertexData.append(&vertex, length: vertexSize)
    }

    return vertexData
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

    renderEncoder.setFragmentTexture(
      texture,
      index: Int(TextureIndexBaseColor.rawValue)
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
