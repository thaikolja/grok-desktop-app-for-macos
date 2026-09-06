import AppKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            Text("Grok Desktop")
                .font(.title2.weight(.semibold))
            Text("by Kolja Nolte")
                .font(.callout)
            Text("Version \(Bundle.main.shortVersion) (\(Bundle.main.buildVersion))")
                .foregroundStyle(.secondary)
            Text("A native macOS client for grok.com.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Not affiliated with xAI.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 320)
        .padding(28)
    }
}

extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
