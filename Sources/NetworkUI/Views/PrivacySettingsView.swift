import SwiftUI

struct PrivacySettingsView: View {
    @State private var logger = NetworkLogger.shared
    @State private var newHeaderKey = ""
    @State private var showingAddHeader = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Exclude Sensitive Headers", isOn: $logger.privacySettings.excludeSensitiveHeaders)
                    Toggle("Exclude Request Bodies", isOn: $logger.privacySettings.excludeRequestBody)
                    Toggle("Exclude Response Bodies", isOn: $logger.privacySettings.excludeResponseBody)
                } header: {
                    Text("Privacy Options")
                } footer: {
                    Text("When enabled, sensitive information will be excluded from exports and sharing.")
                }
                
                Section {
                    ForEach(Array(logger.privacySettings.sensitiveHeaderKeys).sorted(), id: \.self) { headerKey in
                        HStack {
                            Text(headerKey)
                                .font(.body)
                            Spacer()
                            Button("Remove") {
                                logger.privacySettings.removeSensitiveHeader(headerKey)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    
                    Button("Add Custom Header") {
                        showingAddHeader = true
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("Sensitive Headers")
                } footer: {
                    Text("Headers that contain sensitive information like tokens, cookies, or API keys.")
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Add Sensitive Header", isPresented: $showingAddHeader) {
            TextField("Header Key", text: $newHeaderKey)
            Button("Add") {
                if !newHeaderKey.isEmpty {
                    logger.privacySettings.addSensitiveHeader(newHeaderKey)
                    newHeaderKey = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newHeaderKey = ""
            }
        } message: {
            Text("Enter the header key that should be excluded from exports (e.g., 'X-Custom-Token').")
        }
    }
}

#Preview {
    PrivacySettingsView()
}