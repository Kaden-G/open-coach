import SwiftUI

// PROFILE-002: LLM API Key Configuration

struct APIKeyConfigView: View {
    @State private var selectedProvider: LLMProviderType = .openAI
    @State private var apiKey = ""
    @State private var isSaved = false
    @State private var isTesting = false
    @State private var testResult: String?

    var body: some View {
        Form {
            Section {
                Text("Paste your own API key to enable AI-enhanced coaching. This is optional — the app works fully offline without it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Provider") {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(LLMProviderType.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedProvider) { _, newValue in
                    apiKey = KeychainHelper.read(key: newValue.keychainKey) ?? ""
                    isSaved = !apiKey.isEmpty
                    testResult = nil
                }
            }

            Section("API Key") {
                SecureField("Paste your API key", text: $apiKey)
                    .textContentType(.none)
                    .autocorrectionDisabled()

                if isSaved {
                    Label("Key saved in Keychain", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    saveKey()
                } label: {
                    Text("Save Key")
                        .frame(maxWidth: .infinity)
                }
                .disabled(apiKey.isEmpty)

                Button {
                    testConnection()
                } label: {
                    if isTesting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Test Connection")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(apiKey.isEmpty || isTesting)

                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(result.contains("Success") ? .green : .red)
                }
            }

            Section {
                Button("Remove Key", role: .destructive) {
                    KeychainHelper.delete(key: selectedProvider.keychainKey)
                    apiKey = ""
                    isSaved = false
                    testResult = nil
                }
                .disabled(!isSaved)
            }
        }
        .navigationTitle("API Configuration")
        .onAppear {
            apiKey = KeychainHelper.read(key: selectedProvider.keychainKey) ?? ""
            isSaved = !apiKey.isEmpty
        }
    }

    private func saveKey() {
        try? KeychainHelper.save(key: selectedProvider.keychainKey, value: apiKey)
        isSaved = true
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        let config = LLMConfiguration(provider: selectedProvider, apiKey: apiKey)
        let client = LLMClient(config: config)

        Task {
            do {
                let response = try await client.send(prompt: "Respond with just the word 'connected'.")
                await MainActor.run {
                    testResult = "Success: \(response.content.prefix(50)) (\(response.tokensUsed) tokens)"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}
