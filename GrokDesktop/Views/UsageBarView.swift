import SwiftUI

struct UsageBarView: View {
    @ObservedObject var rateLimits: RateLimitService
    @ObservedObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 20) {
            UsageStat(label: "Low Effort", value: rateLimits.snapshot.lowLabel, severity: rateLimits.snapshot.severity(remaining: rateLimits.snapshot.lowRemaining, total: rateLimits.snapshot.lowTotal))
            UsageStat(label: "High Effort", value: rateLimits.snapshot.highLabel, severity: rateLimits.snapshot.severity(remaining: rateLimits.snapshot.highRemaining, total: rateLimits.snapshot.highTotal))

            if !settings.hideGrok4Heavy {
                UsageStat(label: "Grok 4 Heavy", value: rateLimits.snapshot.grok4Label, severity: rateLimits.snapshot.severity(remaining: rateLimits.snapshot.grok4Remaining, total: rateLimits.snapshot.grok4Total))
            }

            if rateLimits.snapshot.refillSeconds > 0 {
                UsageStat(label: "Refill", value: rateLimits.snapshot.refillLabel, severity: .ok, accent: true)
            }

            Spacer()

            Button {
                settings.hideGrok4Heavy.toggle()
            } label: {
                Image(systemName: settings.hideGrok4Heavy ? "eye.slash" : "eye")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(settings.hideGrok4Heavy ? "Show Grok 4 Heavy" : "Hide Grok 4 Heavy")
        }
        .font(.system(size: 11))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

private struct UsageStat: View {
    let label: String
    let value: String
    let severity: RateLimitSeverity
    var accent: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    private var color: Color {
        if accent { return Color.accentColor }
        switch severity {
        case .ok: return Color.primary
        case .warning: return Color.orange
        case .critical: return Color.red
        }
    }
}
