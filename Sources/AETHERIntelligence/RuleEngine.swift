import Foundation
import AETHERShared

public actor RuleEngine {
    private var rules: [AetherRule] = []
    public init() {}
    public func replaceRules(_ newRules: [AetherRule]) { rules = newRules }
    public func allRules() -> [AetherRule] { rules }
    public func matchingRules(bundleIdentifier: String?) -> [AetherRule] {
        rules.filter { $0.enabled && $0.bundleIdentifier == bundleIdentifier }
    }
}
