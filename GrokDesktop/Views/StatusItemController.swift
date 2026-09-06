import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    static let shared = StatusItemController()

    private var item: NSStatusItem?

    func setVisible(_ visible: Bool) {
        if visible {
            if item == nil {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                item.button?.title = "Grok"
                item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
                item.button?.target = self
                item.button?.action = #selector(activateApp)
                let menu = NSMenu()
                let open = NSMenuItem(title: "Open Grok Desktop", action: #selector(activateApp), keyEquivalent: "")
                open.target = self
                menu.addItem(open)
                menu.addItem(.separator())
                menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                item.menu = menu
                self.item = item
            }
        } else if let item {
            NSStatusBar.system.removeStatusItem(item)
            self.item = nil
        }
    }

    func update(snapshot: RateLimitSnapshot) {
        guard let button = item?.button else { return }
        if snapshot.unauthorized {
            button.title = "Grok · sign in"
            return
        }
        if let low = snapshot.lowRemaining, let total = snapshot.lowTotal {
            button.title = "Grok \(low)/\(total)"
        } else {
            button.title = "Grok"
        }
    }

    @objc func activateApp() {
        Task { @MainActor in
            MainWindowController.shared.reveal()
        }
    }
}
