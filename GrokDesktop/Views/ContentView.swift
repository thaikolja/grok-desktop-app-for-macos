import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var session = GrokSession()
    @StateObject private var rateLimits = RateLimitService()
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingAbout = false
    @State private var eventMonitors: [Any] = []

    var body: some View {
        VStack(spacing: 0) {
            if session.showsReturnToGrok {
                Button(action: session.returnToGrok) {
                    Label("Grok", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(.bar)
                .overlay(alignment: .bottom) { Divider() }
                .help("Back to Grok")
            }

            if session.findVisible {
                FindBarView(session: session)
            }

            ZStack {
                GrokWebView(webView: session.webView)
                if let layer = session.authLayers.last {
                    GrokWebView(webView: layer.webView)
                }
            }

            if settings.showUsageBar {
                UsageBarView(rateLimits: rateLimits, settings: settings)
            }
        }
        .background(WindowConfigurator(
            alwaysOnTop: settings.alwaysOnTop,
            title: session.title
        ))
        .background(MainWindowBinder())
        .toolbar(.hidden)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .modifier(GrokCommandListeners(
            session: session,
            settings: settings,
            showingAbout: $showingAbout
        ))
        .onAppear(perform: setup)
        .onDisappear(perform: teardown)
        .onChange(of: settings.showUsageBar) { _, active in
            rateLimits.setActive(active)
        }
        .onChange(of: settings.showStatusItem) { _, visible in
            StatusItemController.shared.setVisible(visible)
        }
        .onChange(of: rateLimits.snapshot) { _, snap in
            StatusItemController.shared.update(snapshot: snap)
        }
        .onChange(of: settings.pageZoom) { _, _ in
            session.applyZoom()
        }
        .onChange(of: settings.useSafariUserAgent) { _, _ in
            session.applyUserAgent()
            session.reload()
        }
    }

    private func setup() {
        rateLimits.attach { [weak session] in
            session?.grokWebView
        }
        rateLimits.setActive(settings.showUsageBar)
        if eventMonitors.isEmpty {
            eventMonitors = KeyboardMonitor.install()
        }
        StatusItemController.shared.setVisible(settings.showStatusItem)
    }

    private func teardown() {
        rateLimits.setActive(false)
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        eventMonitors.removeAll()
    }
}

private struct GrokCommandListeners: ViewModifier {
    @ObservedObject var session: GrokSession
    @ObservedObject var settings: AppSettings
    @Binding var showingAbout: Bool

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .grokReload)) { _ in
                session.reload()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokStop)) { _ in
                session.stopLoading()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokFind)) { _ in
                session.findVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokHideFind)) { _ in
                session.hideFind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokReturnHome)) { _ in
                if session.showsReturnToGrok {
                    session.returnToGrok()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokUsage)) { _ in
                settings.showUsageBar.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokAlwaysOnTop)) { _ in
                settings.alwaysOnTop.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokAbout)) { _ in
                showingAbout = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokZoomIn)) { _ in
                session.zoomIn()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokZoomOut)) { _ in
                session.zoomOut()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokZoomReset)) { _ in
                session.zoomReset()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokPrint)) { _ in
                session.printPage()
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokOpenURL)) { note in
                guard let url = note.object as? URL else { return }
                session.openGrokURL(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .grokOpenMainWindow)) { _ in
                MainWindowController.shared.reveal()
            }
    }
}
