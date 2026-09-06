import WebKit
import AppKit

enum WebViewFactory {
    static func make(
        isPrivate: Bool,
        configuration: WKWebViewConfiguration? = nil,
        useSafariUserAgent: Bool
    ) -> WKWebView {
        let config = configuration ?? makeConfiguration(isPrivate: isPrivate, useSafariUserAgent: useSafariUserAgent)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        webView.allowsLinkPreview = true
        if #available(macOS 13.3, *) {
            #if DEBUG
            webView.isInspectable = true
            #endif
        }
        webView.underPageBackgroundColor = NSColor.windowBackgroundColor
        webView.customUserAgent = nil
        return webView
    }

    static func makeConfiguration(isPrivate: Bool, useSafariUserAgent: Bool) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = isPrivate ? .nonPersistent() : .default()
        config.defaultWebpagePreferences.preferredContentMode = .desktop
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences.isElementFullscreenEnabled = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        if !useSafariUserAgent {
            config.applicationNameForUserAgent = "GrokDesktop/1.0"
        }
        config.suppressesIncrementalRendering = false
        return config
    }
}
