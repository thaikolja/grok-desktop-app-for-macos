import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Window") {
                Toggle("Always on top", isOn: $settings.alwaysOnTop)
                Toggle("Show usage stats", isOn: $settings.showUsageBar)
                Toggle("Menu bar extra", isOn: $settings.showStatusItem)
            }
            Section("Display") {
                Toggle("Safari user agent", isOn: $settings.useSafariUserAgent)
                HStack {
                    Text("Zoom")
                    Spacer()
                    Text("\(Int(settings.pageZoom * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $settings.pageZoom, in: 0.75...2.0, step: 0.05)
            }
            Section {
                Text("Grok Desktop is a native macOS app by Kolja Nolte. It is not affiliated with xAI.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 360)
    }
}
