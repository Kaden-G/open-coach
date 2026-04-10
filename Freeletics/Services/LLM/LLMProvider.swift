import Foundation

enum LLMProviderType: String, Codable, CaseIterable {
    case openAI = "openai"
    case anthropic = "anthropic"

    var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        }
    }

    var baseURL: String {
        switch self {
        case .openAI: "https://api.openai.com/v1/chat/completions"
        case .anthropic: "https://api.anthropic.com/v1/messages"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: "gpt-4o"
        case .anthropic: "claude-sonnet-4-20250514"
        }
    }

    var keychainKey: String {
        "llm_api_key_\(rawValue)"
    }
}

struct LLMConfiguration {
    let provider: LLMProviderType
    let apiKey: String
    let model: String

    init(provider: LLMProviderType, apiKey: String, model: String? = nil) {
        self.provider = provider
        self.apiKey = apiKey
        self.model = model ?? provider.defaultModel
    }

    static func load(provider: LLMProviderType) -> LLMConfiguration? {
        guard let key = KeychainHelper.read(key: provider.keychainKey) else { return nil }
        return LLMConfiguration(provider: provider, apiKey: key)
    }

    static var current: LLMConfiguration? {
        // Try OpenAI first, then Anthropic
        if let config = load(provider: .openAI) { return config }
        if let config = load(provider: .anthropic) { return config }
        return nil
    }
}
