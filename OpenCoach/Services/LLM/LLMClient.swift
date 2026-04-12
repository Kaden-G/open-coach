import Foundation

// Unified LLM client supporting both OpenAI and Anthropic REST APIs.
// No SDK dependency — direct URLSession calls.

actor LLMClient {
    private let config: LLMConfiguration

    init(config: LLMConfiguration) {
        self.config = config
    }

    struct LLMResponse {
        let content: String
        let tokensUsed: Int
    }

    enum LLMError: Error, LocalizedError {
        case invalidResponse
        case apiError(String)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: "Invalid response from API"
            case .apiError(let msg): "API error: \(msg)"
            case .networkError(let err): "Network error: \(err.localizedDescription)"
            }
        }
    }

    func send(prompt: String, systemPrompt: String? = nil) async throws -> LLMResponse {
        switch config.provider {
        case .openAI:
            return try await sendOpenAI(prompt: prompt, systemPrompt: systemPrompt)
        case .anthropic:
            return try await sendAnthropic(prompt: prompt, systemPrompt: systemPrompt)
        }
    }

    // MARK: - OpenAI

    private func sendOpenAI(prompt: String, systemPrompt: String?) async throws -> LLMResponse {
        var messages: [[String: String]] = []
        if let system = systemPrompt {
            messages.append(["role": "system", "content": system])
        }
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "max_tokens": 2000,
            "temperature": 0.7,
        ]

        var request = URLRequest(url: URL(string: config.provider.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            if let error = json?["error"] as? [String: Any], let msg = error["message"] as? String {
                throw LLMError.apiError(msg)
            }
            throw LLMError.invalidResponse
        }

        let usage = json?["usage"] as? [String: Any]
        let tokens = usage?["total_tokens"] as? Int ?? 0

        return LLMResponse(content: content, tokensUsed: tokens)
    }

    // MARK: - Anthropic

    private func sendAnthropic(prompt: String, systemPrompt: String?) async throws -> LLMResponse {
        var body: [String: Any] = [
            "model": config.model,
            "max_tokens": 2000,
            "messages": [["role": "user", "content": prompt]],
        ]
        if let system = systemPrompt {
            body["system"] = system
        }

        var request = URLRequest(url: URL(string: config.provider.baseURL)!)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let contentBlocks = json?["content"] as? [[String: Any]],
              let text = contentBlocks.first?["text"] as? String else {
            if let error = json?["error"] as? [String: Any], let msg = error["message"] as? String {
                throw LLMError.apiError(msg)
            }
            throw LLMError.invalidResponse
        }

        let usage = json?["usage"] as? [String: Any]
        let inputTokens = usage?["input_tokens"] as? Int ?? 0
        let outputTokens = usage?["output_tokens"] as? Int ?? 0

        return LLMResponse(content: text, tokensUsed: inputTokens + outputTokens)
    }
}
