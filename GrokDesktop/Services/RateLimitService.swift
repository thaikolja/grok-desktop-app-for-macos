import Combine
import Foundation
import WebKit

@MainActor
final class RateLimitService: ObservableObject {
    @Published var snapshot = RateLimitSnapshot.empty
    @Published var lastUpdated: Date?

    private var timer: Timer?
    private var provider: (() -> WKWebView?)?

    static let pollInterval: TimeInterval = 5

    func attach(provider: @escaping () -> WKWebView?) {
        self.provider = provider
    }

    func setActive(_ active: Bool) {
        timer?.invalidate()
        timer = nil
        guard active else { return }
        refresh()
        let timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func refresh() {
        guard let webView = provider?() else {
            snapshot.error = "No Grok tab"
            return
        }
        Task {
            await self.refresh(from: webView)
        }
    }

    func refresh(from webView: WKWebView) async {
        do {
            let raw = try await webView.callAsyncJavaScript(
                Self.script,
                arguments: [:],
                in: nil,
                contentWorld: .page
            )
            snapshot = RateLimitParser.parse(raw ?? [:])
            lastUpdated = Date()
        } catch {
            snapshot.error = error.localizedDescription
        }
    }

    /// Function body for `callAsyncJavaScript` (not an IIFE).
    /// Runs inside the grok.com page so the signed-in cookie jar is used.
    private static let script = """
    async function fetchRateLimits(requestKind, modelName) {
      try {
        const response = await fetch('https://grok.com/rest/rate-limits', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify({ requestKind: requestKind, modelName: modelName })
        });
        if (response.status === 401 || response.status === 403) {
          return { error: 'UNAUTHORIZED' };
        }
        if (!response.ok) {
          return { error: 'HTTP ' + response.status };
        }
        return await response.json();
      } catch (e) {
        return { error: String(e && e.message ? e.message : e) };
      }
    }
    const defaultLimits = await fetchRateLimits('DEFAULT', 'grok-3');
    const grok4HeavyLimits = await fetchRateLimits('DEFAULT', 'grok-4-heavy');
    return { DEFAULT: defaultLimits, GROK4HEAVY: grok4HeavyLimits };
    """
}
