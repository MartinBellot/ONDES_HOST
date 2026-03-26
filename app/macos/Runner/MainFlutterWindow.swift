import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // ── Window chrome ──────────────────────────────────────────────────────
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true

    // ── Native macOS vibrancy (frosted-glass behind-window blur) ───────────
    // Makes the entire window translucent, blending with whatever is behind it.
    // Flutter's scaffold background must be Colors.transparent on macOS for
    // this to render correctly (see main.dart).
    self.isOpaque = false
    self.backgroundColor = .clear

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()

    // Inject NSVisualEffectView behind the Flutter render canvas.
    // After super.awakeFromNib() the view hierarchy is fully wired:
    //   NSWindow.contentView (NSView)
    //     └─ FlutterViewController.view (FlutterView)  ← subviews.first
    if let contentView = self.contentView {
      let effect = NSVisualEffectView(frame: contentView.bounds)
      effect.autoresizingMask = [.width, .height]
      // .behindWindow blurs the desktop/content behind the window.
      effect.blendingMode = .behindWindow
      // .windowBackground adapts to the system dark/light appearance.
      // Pair with NSApp.appearance = .darkAqua in AppDelegate for a
      // consistent dark frosted-glass render.
      effect.material = .windowBackground
      effect.state = .active
      // Insert below the Flutter view so Flutter renders on top.
      let flutterView = contentView.subviews.first
      contentView.addSubview(effect, positioned: .below, relativeTo: flutterView)
    }
  }
}

