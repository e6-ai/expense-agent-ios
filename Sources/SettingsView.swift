import SwiftUI

struct SettingsView: View {
    @ObservedObject private var keyManager = APIKeyManager.shared
    @State private var keyInput = ""
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if showKey {
                            TextField("sk-...", text: $keyInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $keyInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Button(action: { showKey.toggle() }) {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if keyInput != keyManager.apiKey {
                        Button("Save API Key") {
                            keyManager.apiKey = keyInput
                        }
                        .foregroundStyle(.orange)
                    } else if !keyManager.apiKey.isEmpty {
                        Label("Key saved in Keychain", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Your API key is stored securely in the iOS Keychain and never leaves your device except for OpenAI API calls.")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Model", value: "GPT-4o Vision")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                keyInput = keyManager.apiKey
            }
        }
    }
}
