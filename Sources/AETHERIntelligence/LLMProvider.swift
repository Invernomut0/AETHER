import Foundation

public struct LLMCommand: Sendable {
    public let text: String
}

public struct LLMCommandResult: Sendable {
    public let intent: String
    public let arguments: [String: String]
}

public protocol LLMCommandInterpreting: Sendable {
    func interpret(_ command: LLMCommand) async throws -> LLMCommandResult
}

/// Network transport and provider configuration are intentionally not enabled by default.
/// A production implementation must require explicit endpoint selection and never transmit
/// captured window pixels or sensitive window titles.
public struct DisabledLLMProvider: LLMCommandInterpreting {
    public init() {}
    public func interpret(_ command: LLMCommand) async throws -> LLMCommandResult {
        throw NSError(domain: "AETHER.LLM", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "LLM provider is not configured"
        ])
    }
}
