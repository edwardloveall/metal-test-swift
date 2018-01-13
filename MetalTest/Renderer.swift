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
    let clear = MTLClearColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
    view.clearColor = clear
    let commandBuffer = commandQueue?.makeCommandBuffer()
    commandBuffer?.label = "MyCommand"
    if let renderPassDescriptor = view.currentRenderPassDescriptor {
      let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
      renderEncoder?.label = "MyRenderEncoder"
      renderEncoder?.endEncoding()
      if let currentDrawable = view.currentDrawable {
        commandBuffer?.present(currentDrawable)
      }
    }
    commandBuffer?.commit()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
