import AppKit
import SwiftUI

/// Reopens the SwiftUI `WindowGroup(id: "main")` without creating a stray extra tab.
@MainActor
final class MainWindowController {
    static let shared = MainWindowController()
    static let identifier = "GrokDesktop.Main"

    var openWindow: ((String) -> Void)?

    static func isMainWindow(_ window: NSWindow?) -> Bool {
        window?.identifier?.rawValue == identifier
    }

    /// Dock reopen: only order an existing window front. Returning `true` from
    /// `applicationShouldHandleReopen` lets SwiftUI restore the group if none exist.
    func orderFrontExisting() {
        NSApp.activate(ignoringOtherApps: true)
        guard let window = mainWindows.first else { return }
        window.makeKeyAndOrderFront(nil)
    }

    /// Status-item / explicit "Open" path: order front, or ask SwiftUI to create the window.
    func reveal() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = mainWindows.first {
            window.makeKeyAndOrderFront(nil)
            return
        }
        openWindow?("main")
    }

    private var mainWindows: [NSWindow] {
        NSApp.windows.filter { Self.isMainWindow($0) }
    }
}

struct MainWindowBinder: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear {
                MainWindowController.shared.openWindow = { id in
                    openWindow(id: id)
                }
            }
    }
}
