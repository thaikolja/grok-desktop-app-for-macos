import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    var alwaysOnTop: Bool
    var title: String

    func makeNSView(context: Context) -> ProbeView {
        let view = ProbeView(frame: .zero)
        DispatchQueue.main.async { apply(view) }
        return view
    }

    func updateNSView(_ nsView: ProbeView, context: Context) {
        apply(nsView)
    }

    private func apply(_ view: ProbeView) {
        guard let window = view.window else { return }
        window.identifier = NSUserInterfaceItemIdentifier(MainWindowController.identifier)
        window.title = title
        window.level = alwaysOnTop ? .floating : .normal
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.collectionBehavior.insert(.managed)
        window.tabbingMode = .disallowed
        window.setFrameAutosaveName("GrokDesktop.Main")
        window.minSize = NSSize(width: 800, height: 600)
        window.isMovableByWindowBackground = false
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.toolbarStyle = .automatic
        if alwaysOnTop && view.alwaysOnTopApplied != true {
            window.orderFrontRegardless()
        }
        view.alwaysOnTopApplied = alwaysOnTop
    }

    final class ProbeView: NSView {
        var alwaysOnTopApplied: Bool?
    }
}

enum KeyboardMonitor {
    static func install() -> [Any] {
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                NotificationCenter.default.post(name: .grokHideFind, object: nil)
            }
            return event
        }
        return [monitor].compactMap { $0 }
    }
}
