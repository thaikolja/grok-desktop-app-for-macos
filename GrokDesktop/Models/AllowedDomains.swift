import Foundation

/// Allowlist for top-level navigations and window.open.
/// Subresource loads (CDN, APIs) are not filtered — only document navigations.
enum AllowedDomains {
    static let grokHome = URL(string: "https://grok.com")!

    static func isInternal(_ url: URL) -> Bool {
        if isOAuthScheme(url) { return true }
        if let scheme = url.scheme?.lowercased(), scheme != "http" && scheme != "https" {
            return false
        }
        guard let host = url.host?.lowercased() else { return false }
        return isAuthFamily(host: host)
    }

    /// Google Identity Services talks back via `storagerelay://…`.
    static func isOAuthScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        if scheme == "about" || scheme == "blob" || scheme == "data" { return true }
        if scheme == "storagerelay" || scheme.hasPrefix("storagerelay") { return true }
        return false
    }

    static func isLoopback(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "::1" || host == "0.0.0.0"
    }

    /// Grok, xAI, Google sign-in (including google.de), Apple ID.
    static func isAuthFamily(_ url: URL) -> Bool {
        if isOAuthScheme(url) { return true }
        guard let host = url.host?.lowercased() else { return false }
        return isAuthFamily(host: host)
    }

    static func isAuthFamily(host: String) -> Bool {
        let h = host.lowercased()
        if h == "grok.com" || h.hasSuffix(".grok.com") { return true }
        if h == "x.ai" || h.hasSuffix(".x.ai") { return true }
        if h == "x.com" || h.hasSuffix(".x.com") { return true }
        if isGoogleFamily(h) { return true }
        if h == "apple.com" || h.hasSuffix(".apple.com") { return true }
        if h == "appleid.apple.com" || h == "idmsa.apple.com" { return true }
        return false
    }

    static func isGoogleFamily(_ host: String) -> Bool {
        let h = host.lowercased()
        if h == "google.com" || h.hasSuffix(".google.com") { return true }
        if h == "googleapis.com" || h.hasSuffix(".googleapis.com") { return true }
        if h == "gstatic.com" || h.hasSuffix(".gstatic.com") { return true }
        if h == "googleusercontent.com" || h.hasSuffix(".googleusercontent.com") { return true }
        if h == "youtube.com" || h.hasSuffix(".youtube.com") { return true }
        if h == "recaptcha.net" || h.hasSuffix(".recaptcha.net") { return true }
        if h == "gvt1.com" || h.hasSuffix(".gvt1.com") { return true }
        if h == "gvt2.com" || h.hasSuffix(".gvt2.com") { return true }
        if h == "withgoogle.com" || h.hasSuffix(".withgoogle.com") { return true }
        // google.de, accounts.google.de, www.google.co.uk, …
        let labels = h.split(separator: ".")
        if labels.contains("google") { return true }
        return false
    }

    static func isSafeExternal(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        guard scheme == "http" || scheme == "https" else { return false }
        guard let host = url.host?.lowercased(), !host.isEmpty, host.count <= 253 else { return false }
        if host == "localhost" || host == "127.0.0.1" || host == "0.0.0.0" || host == "::1" {
            return false
        }
        if host.hasPrefix("192.168.") || host.hasPrefix("10.") || host.hasPrefix("172.") {
            return false
        }
        return !isInternal(url)
    }

    static func isAppleAuth(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "appleid.apple.com" || host == "idmsa.apple.com" || host.hasSuffix(".apple.com")
    }

    static func isGrok(host: String) -> Bool {
        let h = host.lowercased()
        return h == "grok.com" || h.hasSuffix(".grok.com")
    }

    static func isGrok(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return isGrok(host: host)
    }
}
