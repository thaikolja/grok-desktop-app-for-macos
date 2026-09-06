import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Grok Desktop") {
                NotificationCenter.default.post(name: .grokAbout, object: nil)
            }
        }

        CommandGroup(after: .toolbar) {
            Button("Reload") {
                NotificationCenter.default.post(name: .grokReload, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Stop") {
                NotificationCenter.default.post(name: .grokStop, object: nil)
            }
            .keyboardShortcut(".", modifiers: .command)

            Button("Find…") {
                NotificationCenter.default.post(name: .grokFind, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("Actual Size") {
                NotificationCenter.default.post(name: .grokZoomReset, object: nil)
            }
            .keyboardShortcut("0", modifiers: .command)

            Button("Zoom In") {
                NotificationCenter.default.post(name: .grokZoomIn, object: nil)
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                NotificationCenter.default.post(name: .grokZoomOut, object: nil)
            }
            .keyboardShortcut("-", modifiers: .command)

            Divider()

            Button("Usage Stats") {
                NotificationCenter.default.post(name: .grokUsage, object: nil)
            }
            .keyboardShortcut("u", modifiers: .command)

            Button("Always on Top") {
                NotificationCenter.default.post(name: .grokAlwaysOnTop, object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command, .option])
        }

        CommandGroup(replacing: .printItem) {
            Button("Print…") {
                NotificationCenter.default.post(name: .grokPrint, object: nil)
            }
            .keyboardShortcut("p", modifiers: .command)
        }
    }
}
