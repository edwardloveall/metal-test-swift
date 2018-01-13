import simd
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
  let device: MTLDevice?
  let commandQueue: MTLCommandQueue?

  init(mtkView: MTKView) {
    device = mtkView.device
    commandQueue = device?.makeCommandQueue()
  }

  func draw(in view: MTKView) {
    guard
      let currentDrawable = view.currentDrawable,
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue?.makeCommandBuffer(),
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    else {
      return
    }

    commandBuffer.label = "MyCommand"
    renderEncoder.label = "MyRenderEncoder"

    view.clearColor = MTLClearColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
    renderEncoder.endEncoding()

    commandBuffer.present(currentDrawable)
    commandBuffer.commit()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
