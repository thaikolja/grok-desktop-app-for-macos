import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Key {
        static let alwaysOnTop = "alwaysOnTop"
        static let showUsageBar = "showUsageBar"
        static let hideGrok4Heavy = "hideGrok4Heavy"
        static let pageZoom = "pageZoom"
        static let showStatusItem = "showStatusItem"
        static let customUserAgent = "customUserAgent"
        static let lastURL = "lastURL"
    }

    @Published var alwaysOnTop: Bool {
        didSet { defaults.set(alwaysOnTop, forKey: Key.alwaysOnTop) }
    }

    @Published var showUsageBar: Bool {
        didSet { defaults.set(showUsageBar, forKey: Key.showUsageBar) }
    }

    @Published var hideGrok4Heavy: Bool {
        didSet { defaults.set(hideGrok4Heavy, forKey: Key.hideGrok4Heavy) }
    }

    @Published var pageZoom: Double {
        didSet { defaults.set(pageZoom, forKey: Key.pageZoom) }
    }

    @Published var showStatusItem: Bool {
        didSet { defaults.set(showStatusItem, forKey: Key.showStatusItem) }
    }

    @Published var useSafariUserAgent: Bool {
        didSet { defaults.set(useSafariUserAgent, forKey: Key.customUserAgent) }
    }

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        alwaysOnTop = defaults.bool(forKey: Key.alwaysOnTop)
        showUsageBar = defaults.bool(forKey: Key.showUsageBar)
        hideGrok4Heavy = defaults.bool(forKey: Key.hideGrok4Heavy)
        let zoom = defaults.double(forKey: Key.pageZoom)
        pageZoom = zoom == 0 ? 1.0 : min(2.0, max(0.75, zoom))
        showStatusItem = defaults.bool(forKey: Key.showStatusItem)
        useSafariUserAgent = defaults.object(forKey: Key.customUserAgent) as? Bool ?? true
    }

    var homeURL: URL { AllowedDomains.grokHome }

    func saveLastURL(_ url: URL) {
        guard AllowedDomains.isInternal(url) else { return }
        defaults.set(url.absoluteString, forKey: Key.lastURL)
    }

    func loadLastURL() -> URL? {
        guard let raw = defaults.string(forKey: Key.lastURL),
              let url = URL(string: raw),
              AllowedDomains.isInternal(url) else { return nil }
        return url
    }
}
