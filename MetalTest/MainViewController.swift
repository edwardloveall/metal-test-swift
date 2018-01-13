import AppKit
import MetalKit

class MainViewController: NSViewController {
  var renderer: Renderer?

  override func viewDidLoad() {
    guard
      let metalView = view as? MTKView,
      let device = MTLCreateSystemDefaultDevice()
    else {
      fatalError("Metal is not supported on this device")
    }
    metalView.device = device
    renderer = Renderer(mtkView: metalView)
    metalView.delegate = renderer
    metalView.preferredFramesPerSecond = 60
  }
}
