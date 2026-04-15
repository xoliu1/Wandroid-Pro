import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 设置最小窗口尺寸
    self.minSize = NSSize(width: 400, height: 600)
    // 设置默认窗口尺寸
    self.setContentSize(NSSize(width: 1024, height: 768))
    // 居中显示
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
