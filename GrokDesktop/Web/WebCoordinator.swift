import AppKit
import WebKit

final class WebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    let isPopup: Bool
    weak var session: GrokSession?

    init(isPopup: Bool) {
        self.isPopup = isPopup
        super.init()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.scheme == "grok" {
            decisionHandler(.cancel)
            Task { @MainActor in
                self.session?.openGrokURL(url)
            }
            return
        }

        if AllowedDomains.isOAuthScheme(url) || AllowedDomains.isInternal(url) {
            decisionHandler(.allow)
            return
        }

        if AllowedDomains.isLoopback(url),
           url.scheme == "http" || url.scheme == "https" {
            decisionHandler(.allow)
            return
        }

        if navigationAction.targetFrame?.isMainFrame == false {
            if url.scheme == "https" || url.scheme == "http" {
                decisionHandler(.allow)
                return
            }
        }

        // Login must never leave WKWebView. Opening Chrome/Safari completes
        // Google in the browser; grok.com in the app never gets the callback.
        let inAuth = isPopup || AllowedDomains.isAuthFamily(webView.url ?? url)
        if inAuth {
            if url.scheme == "https" || url.scheme == "http" {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
            return
        }

        if AllowedDomains.isSafeExternal(url) {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.cancel)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        applyAppleAuthAppearance(webView)
        Task { @MainActor in
            self.session?.pageDidCommit(webView)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        applyAppleAuthAppearance(webView)
        Task { @MainActor in
            self.session?.pageDidFinish(webView)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.session?.pageDidFail(webView, error: error)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.session?.pageDidFail(webView, error: error)
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Google GeneralOAuthFlow (legacy/consent) is a top-level redirect, not a
        // real popup. A second WKWebView / Safari open drops the OAuth cookies and
        // Google returns HTTP 400 on the callback. Stay in this web view.
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                self.session?.handleWindowOpen(
                    from: webView,
                    configuration: configuration,
                    action: navigationAction
                )
            }
        }
        return nil
    }

    func webViewDidClose(_ webView: WKWebView) {
        guard isPopup else { return }
        Task { @MainActor in
            self.session?.dismissPopup(containing: webView)
        }
    }

    @available(macOS 12.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        if origin.`protocol` == "https" && AllowedDomains.isGrok(host: origin.host) {
            decisionHandler(.grant)
        } else {
            decisionHandler(.deny)
        }
    }

    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping ([URL]?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.begin { response in
            completionHandler(response == .OK ? panel.urls : nil)
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = webView.title ?? "Grok"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = webView.title ?? "Grok"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        completionHandler(alert.runModal() == .alertFirstButtonReturn)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = webView.title ?? "Grok"
        alert.informativeText = prompt
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(string: defaultText ?? "")
        field.frame = NSRect(x: 0, y: 0, width: 240, height: 24)
        alert.accessoryView = field
        let result = alert.runModal()
        completionHandler(result == .alertFirstButtonReturn ? field.stringValue : nil)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        Task { @MainActor in
            DownloadManager.shared.chooseDestination(suggestedFilename: suggestedFilename, completion: completionHandler)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        Task { @MainActor in
            DownloadManager.shared.didFinish()
        }
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        Task { @MainActor in
            DownloadManager.shared.didFail(error)
        }
    }

    private func applyAppleAuthAppearance(_ webView: WKWebView) {
        guard let url = webView.url, AllowedDomains.isAppleAuth(url) else {
            webView.appearance = nil
            return
        }
        webView.appearance = NSAppearance(named: .aqua)
        let css = """
        :root { color-scheme: light !important; }
        html, body { background: #ffffff !important; color: #000000 !important; }
        """
        let js = """
        (function() {
          var s = document.getElementById('grok-apple-light');
          if (!s) {
            s = document.createElement('style');
            s.id = 'grok-apple-light';
            (document.head || document.documentElement).appendChild(s);
          }
          s.textContent = \(css.jsStringLiteral);
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}

private extension String {
    var jsStringLiteral: String {
        let escaped = self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"" + escaped + "\""
    }
}
