import Foundation

struct RateLimitSnapshot: Equatable {
    var lowRemaining: Int?
    var lowTotal: Int?
    var highRemaining: Int?
    var highTotal: Int?
    var grok4Remaining: Int?
    var grok4Total: Int?
    var refillSeconds: Int
    var unauthorized: Bool
    var error: String?

    static let empty = RateLimitSnapshot(
        lowRemaining: nil,
        lowTotal: nil,
        highRemaining: nil,
        highTotal: nil,
        grok4Remaining: nil,
        grok4Total: nil,
        refillSeconds: 0,
        unauthorized: false,
        error: nil
    )

    var lowLabel: String {
        format(remaining: lowRemaining, total: lowTotal)
    }

    var highLabel: String {
        format(remaining: highRemaining, total: highTotal)
    }

    var grok4Label: String {
        format(remaining: grok4Remaining, total: grok4Total)
    }

    var refillLabel: String {
        guard refillSeconds > 0 else { return "" }
        let minutes = refillSeconds / 60
        let seconds = refillSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    func severity(remaining: Int?, total: Int?) -> RateLimitSeverity {
        guard let remaining, let total, total > 0 else { return .ok }
        let ratio = Double(remaining) / Double(total)
        if ratio <= 0.10 { return .critical }
        if ratio <= 0.25 { return .warning }
        return .ok
    }

    private func format(remaining: Int?, total: Int?) -> String {
        if unauthorized { return "Login required" }
        if let error { return error }
        guard let remaining else { return "—" }
        if let total {
            return "\(remaining) / \(total)"
        }
        return "\(remaining)"
    }
}

enum RateLimitSeverity {
    case ok, warning, critical
}

enum RateLimitParser {
    static func parse(_ raw: Any) -> RateLimitSnapshot {
        guard let root = raw as? [String: Any] else {
            return RateLimitSnapshot.empty.with(error: "Unexpected response")
        }

        let defaultBlock = root["DEFAULT"] as? [String: Any]
        let heavyBlock = root["GROK4HEAVY"] as? [String: Any]

        if let err = defaultBlock?["error"] as? String {
            var snap = RateLimitSnapshot.empty
            snap.unauthorized = err == "UNAUTHORIZED"
            snap.error = snap.unauthorized ? nil : err
            return snap
        }

        var snap = RateLimitSnapshot.empty
        let low = defaultBlock?["lowEffortRateLimits"] as? [String: Any]
        let high = defaultBlock?["highEffortRateLimits"] as? [String: Any]
        snap.lowRemaining = intValue(low?["remainingQueries"])
        snap.lowTotal = intValue(defaultBlock?["totalTokens"])
        snap.highRemaining = intValue(high?["remainingQueries"])
        if let remainingTotal = snap.lowTotal, let cost = intValue(high?["cost"]), cost > 0 {
            snap.highTotal = remainingTotal / cost
        }
        snap.grok4Remaining = intValue(heavyBlock?["remainingQueries"])
        snap.grok4Total = intValue(heavyBlock?["totalQueries"])
        let lowWait = intValue(low?["waitTimeSeconds"]) ?? 0
        let highWait = intValue(high?["waitTimeSeconds"]) ?? 0
        snap.refillSeconds = max(lowWait, highWait)
        return snap
    }

    private static func intValue(_ raw: Any?) -> Int? {
        if let n = raw as? Int { return n }
        if let n = raw as? Double { return Int(n) }
        if let n = raw as? NSNumber { return n.intValue }
        return nil
    }
}

private extension RateLimitSnapshot {
    func with(error: String) -> RateLimitSnapshot {
        var copy = self
        copy.error = error
        return copy
    }
}
