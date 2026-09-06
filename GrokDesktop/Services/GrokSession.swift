import AppKit
import Combine
import Foundation
import WebKit

final class AuthLayer: Identifiable {
    let id = UUID()
    let webView: WKWebView
    let coordinator: WebCoordinator

    init(webView: WKWebView, coordinator: WebCoordinator) {
        self.webView = webView
        self.coordinator = coordinator
    }
}

@MainActor
final class GrokSession: NSObject, ObservableObject {
    @Published var title = "Grok Desktop"
    @Published var url = AllowedDomains.grokHome
    @Published var findVisible = false
    @Published var findQuery = ""
    @Published var findMatchFound = true
    @Published private(set) var authLayers: [AuthLayer] = []

    let webView: WKWebView

    private let mainCoordinator: WebCoordinator
    private var observers = Set<AnyCancellable>()
    private var persistTask: Task<Void, Never>?
    private var awaitingGrokRefresh = false
    private var isPerformingAuthRefresh = false

    override init() {
        let page = AppSettings.shared.loadLastURL() ?? AppSettings.shared.homeURL
        let webView = WebViewFactory.make(
            isPrivate: false,
            useSafariUserAgent: AppSettings.shared.useSafariUserAgent
        )
        let coordinator = WebCoordinator(isPopup: false)
        self.webView = webView
        self.mainCoordinator = coordinator
        super.init()
        self.url = page
        coordinator.session = self
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        bindKVO()
        applyZoom()
        webView.load(URLRequest(url: page, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    var grokWebView: WKWebView? { webView }

    var showsReturnToGrok: Bool {
        !authLayers.isEmpty || !AllowedDomains.isGrok(url)
    }

    func returnToGrok() {
        awaitingGrokRefresh = false
        isPerformingAuthRefresh = false
        clearAuthLayers()
        hideFind()
        webView.stopLoading()
        webView.load(URLRequest(url: AllowedDomains.grokHome, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30))
    }

    func reload() {
        if NSEvent.modifierFlags.contains(.shift) {
            webView.reloadFromOrigin()
        } else {
            webView.reload()
        }
    }

    func stopLoading() {
        webView.stopLoading()
    }

    func printPage() {
        webView.printView(nil)
    }

    func zoomIn() {
        AppSettings.shared.pageZoom = min(2.0, AppSettings.shared.pageZoom + 0.1)
        applyZoom()
    }

    func zoomOut() {
        AppSettings.shared.pageZoom = max(0.75, AppSettings.shared.pageZoom - 0.1)
        applyZoom()
    }

    func zoomReset() {
        AppSettings.shared.pageZoom = 1.0
        applyZoom()
    }

    func applyZoom() {
        let zoom = CGFloat(AppSettings.shared.pageZoom)
        webView.pageZoom = zoom
        for layer in authLayers {
            layer.webView.pageZoom = zoom
        }
    }

    func applyUserAgent() {
        applyUserAgent(to: webView)
        for layer in authLayers {
            applyUserAgent(to: layer.webView)
        }
    }

    func find(_ query: String, backwards: Bool = false) {
        findQuery = query
        let config = WKFindConfiguration()
        config.caseSensitive = false
        config.backwards = backwards
        config.wraps = true
        webView.find(query, configuration: config) { [weak self] result in
            Task { @MainActor in
                self?.findMatchFound = result.matchFound
            }
        }
    }

    func hideFind() {
        findVisible = false
        findQuery = ""
        webView.find("", configuration: WKFindConfiguration()) { _ in }
    }

    func openGrokURL(_ url: URL) {
        var page = AllowedDomains.grokHome
        if url.scheme == "grok" {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               comps.host == "open" || url.path.hasPrefix("/open"),
               let target = comps.queryItems?.first(where: { $0.name == "url" })?.value,
               let parsed = URL(string: target),
               AllowedDomains.isInternal(parsed) {
                page = parsed
            }
        } else if AllowedDomains.isInternal(url) {
            page = url
        }
        webView.load(URLRequest(url: page, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    /// GET `window.open` stays in the current web view (history + cookies).
    /// POST / about:blank must return a new view with WebKit's configuration so
    /// the POST body is not dropped (that is the Google 400).
    func handleWindowOpen(
        from webView: WKWebView,
        configuration: WKWebViewConfiguration,
        action: WKNavigationAction
    ) -> WKWebView? {
        let url = action.request.url
        let method = action.request.httpMethod?.uppercased() ?? "GET"
        let isBlank = url == nil || url?.scheme == "about"
        let isPost = method == "POST"

        let inAuth = AllowedDomains.isAuthFamily(webView.url ?? url ?? AllowedDomains.grokHome)

        if let url, !(AllowedDomains.isInternal(url) || AllowedDomains.isOAuthScheme(url)) {
            if inAuth, url.scheme == "http" || url.scheme == "https" {
                if isPost || isBlank {
                    return adoptAuthLayer(configuration: configuration)
                }
                webView.load(action.request)
                return nil
            }
            if !inAuth, AllowedDomains.isSafeExternal(url) {
                NSWorkspace.shared.open(url)
            }
            return nil
        }

        if isPost || isBlank {
            return adoptAuthLayer(configuration: configuration)
        }

        webView.load(action.request)
        return nil
    }

    func adoptAuthLayer(configuration: WKWebViewConfiguration) -> WKWebView {
        let view = WebViewFactory.make(
            isPrivate: false,
            configuration: configuration,
            useSafariUserAgent: AppSettings.shared.useSafariUserAgent
        )
        let coordinator = WebCoordinator(isPopup: true)
        coordinator.session = self
        view.navigationDelegate = coordinator
        view.uiDelegate = coordinator
        view.pageZoom = CGFloat(AppSettings.shared.pageZoom)
        authLayers.append(AuthLayer(webView: view, coordinator: coordinator))
        return view
    }

    func dismissPopup(containing webView: WKWebView) {
        clearAuthLayer(webView)
    }

    func pageDidCommit(_ webView: WKWebView) {
        guard webView === self.webView else { return }
        url = webView.url ?? url
        persistSoon()
    }

    func pageDidFinish(_ webView: WKWebView) {
        if webView !== self.webView {
            if let page = webView.url, AllowedDomains.isGrok(page) {
                clearAuthLayers()
                reloadGrokHomeAfterAuth()
            }
            return
        }
        if let pageTitle = webView.title, !pageTitle.isEmpty {
            title = pageTitle
        }
        url = webView.url ?? url
        persistSoon()
        if awaitingGrokRefresh, AllowedDomains.isGrok(url) {
            reloadGrokHomeAfterAuth()
        }
    }

    func pageDidFail(_ webView: WKWebView, error: Error) {
        guard webView === self.webView else { return }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
        if title.isEmpty { title = "Grok Desktop" }
    }

    private func clearAuthLayer(_ webView: WKWebView) {
        guard let index = authLayers.firstIndex(where: { $0.webView === webView }) else { return }
        let layer = authLayers.remove(at: index)
        layer.webView.stopLoading()
        layer.webView.navigationDelegate = nil
        layer.webView.uiDelegate = nil
        layer.coordinator.session = nil
    }

    private func clearAuthLayers() {
        for layer in authLayers {
            layer.webView.stopLoading()
            layer.webView.navigationDelegate = nil
            layer.webView.uiDelegate = nil
            layer.coordinator.session = nil
        }
        authLayers.removeAll()
    }

    private func bindKVO() {
        webView.publisher(for: \.title)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let value, !value.isEmpty else { return }
                self?.title = value
            }
            .store(in: &observers)
        webView.publisher(for: \.url)
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] value in
                guard let self else { return }
                self.url = value
                if !AllowedDomains.isGrok(value) {
                    self.awaitingGrokRefresh = true
                }
                self.persistSoon()
            }
            .store(in: &observers)
    }

    /// Session cookies are set, but grok.com's SPA still shows the logged-out
    /// shell until it boots on a fresh document.
    private func reloadGrokHomeAfterAuth() {
        guard !isPerformingAuthRefresh else { return }
        isPerformingAuthRefresh = true
        awaitingGrokRefresh = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            self.webView.stopLoading()
            self.webView.load(URLRequest(
                url: AllowedDomains.grokHome,
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 30
            ))
            try? await Task.sleep(nanoseconds: 750_000_000)
            self.isPerformingAuthRefresh = false
        }
    }

    private func persistSoon() {
        persistTask?.cancel()
        persistTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self?.persist()
        }
    }

    private func persist() {
        AppSettings.shared.saveLastURL(url)
    }

    private func applyUserAgent(to webView: WKWebView) {
        let useSafari = AppSettings.shared.useSafariUserAgent
        webView.evaluateJavaScript("navigator.userAgent") { result, _ in
            let current = (result as? String) ?? ""
            let stripped = current.replacingOccurrences(of: " GrokDesktop/1.0", with: "")
            if useSafari {
                webView.customUserAgent = stripped.isEmpty ? nil : stripped
            } else if !stripped.isEmpty {
                webView.customUserAgent = stripped + " GrokDesktop/1.0"
            }
        }
    }
}
