import SwiftUI
import WebKit

struct GrokWebView: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView.removeFromSuperview()
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
