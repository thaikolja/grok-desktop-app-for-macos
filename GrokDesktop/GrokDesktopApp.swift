import SwiftUI

@main
struct GrokDesktopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        Window("Grok Desktop", id: "main") {
            ContentView()
                .environmentObject(settings)
                .frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.automatic)
        .commands {
            AppCommands()
        }

        Settings {
            SettingsView()
        }
    }
}
