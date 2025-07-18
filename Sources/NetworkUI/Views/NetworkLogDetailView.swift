import SwiftUI

struct NetworkLogDetailView: View {
    let log: NetworkLogEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Request Info Section
                Section("Request") {
                    HStack {
                        Text(log.method)
                            .font(.headline)
                            .foregroundColor(methodColor(log.method))
                        Spacer()
                        if let statusCode = log.responseStatusCode {
                            Text("\(statusCode)")
                                .font(.headline)
                                .foregroundColor(statusCodeColor(statusCode))
                        }
                    }
                    
                    DetailRow(label: "URL", value: log.url)
                    DetailRow(label: "Time", value: log.timestamp.formatted())
                    
                    if let duration = log.duration {
                        DetailRow(label: "Duration", value: String(format: "%.3f seconds", duration))
                    }
                }
                
                // Request Headers Section
                if !log.requestHeaders.isEmpty {
                    DisclosureGroup("Request Headers") {
                        ForEach(log.requestHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { header in
                            DetailRow(label: header.key, value: header.value)
                        }
                    }
                }
                
                // Request Body Section
                if let requestBody = log.requestBody,
                   let bodyString = String(data: requestBody, encoding: .utf8) {
                    DisclosureGroup("Request Body") {
                        Text(bodyString)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .contextMenu {
                                Button("Copy") {
                                    UIPasteboard.general.string = bodyString
                                }
                            }
                    }
                }
                
                // Response Headers Section
                if let responseHeaders = log.responseHeaders, !responseHeaders.isEmpty {
                    DisclosureGroup("Response Headers") {
                        ForEach(responseHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { header in
                            DetailRow(label: header.key, value: header.value)
                        }
                    }
                }
                
                // Response Body Section
                if let responseBody = log.responseBody {
                    DisclosureGroup("Response Body") {
                        if log.isImage {
                            // Display image preview
                            if let uiImage = UIImage(data: responseBody) {
                                VStack(spacing: 12) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .cornerRadius(8)
                                        .contextMenu {
                                            Button("Copy Image") {
                                                UIPasteboard.general.image = uiImage
                                            }
                                        }
                                    
                                    HStack {
                                        if let contentType = log.contentType {
                                            Text("Type: \(contentType)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if let fileSize = log.fileSizeFormatted {
                                            Text("Size: \(fileSize)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            } else {
                                Text("Unable to display image")
                                    .foregroundColor(.secondary)
                            }
                        } else if let bodyString = String(data: responseBody, encoding: .utf8) {
                            // Display text content
                            Text(bodyString)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .contextMenu {
                                    Button("Copy") {
                                        UIPasteboard.general.string = bodyString
                                    }
                                }
                        } else {
                            // Display binary data info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Binary Data")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                if let contentType = log.contentType {
                                    Text("Type: \(contentType)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let fileSize = log.fileSizeFormatted {
                                    Text("Size: \(fileSize)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("Copy Raw Data") {
                                    UIPasteboard.general.setData(responseBody, forPasteboardType: "public.data")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ShareLink(item: copyAllDetailsText(), preview: SharePreview("Request Details", image: Image(systemName: "network"))) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button("Copy All") {
                            UIPasteboard.general.string = copyAllDetailsText()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func statusCodeColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .orange
        case 400..<500: return .red
        case 500..<600: return .purple
        default: return .gray
        }
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .gray
        }
    }
    
    private func copyAllDetailsText() -> String {
        var content = "=== Request Details ===\n\n"
        content += "Method: \(log.method)\n"
        content += "URL: \(log.url)\n"
        content += "Timestamp: \(log.timestamp)\n"
        
        if let statusCode = log.responseStatusCode {
            content += "Status Code: \(statusCode)\n"
        }
        
        if let duration = log.duration {
            content += "Duration: \(String(format: "%.3f", duration))s\n"
        }
        
        let privacySettings = NetworkLogger.shared.privacySettings
        
        // Request Headers
        let requestHeaders = privacySettings.filteredHeaders(log.requestHeaders)
        if !requestHeaders.isEmpty {
            content += "\n--- Request Headers ---\n"
            for (key, value) in requestHeaders.sorted(by: { $0.key < $1.key }) {
                content += "\(key): \(value)\n"
            }
        }
        
        // Request Body
        if let requestBody = log.requestBody, !privacySettings.excludeRequestBody {
            content += "\n--- Request Body ---\n"
            content += String(data: requestBody, encoding: .utf8) ?? "Binary data"
            content += "\n"
        }
        
        // Response Headers
        if let responseHeaders = log.responseHeaders {
            let filteredResponseHeaders = privacySettings.filteredHeaders(responseHeaders)
            if !filteredResponseHeaders.isEmpty {
                content += "\n--- Response Headers ---\n"
                for (key, value) in filteredResponseHeaders.sorted(by: { $0.key < $1.key }) {
                    content += "\(key): \(value)\n"
                }
            }
        }
        
        // Response Body
        if let responseBody = log.responseBody, !privacySettings.excludeResponseBody {
            content += "\n--- Response Body ---\n"
            content += String(data: responseBody, encoding: .utf8) ?? "Binary data"
            content += "\n"
        }
        
        // Privacy notice
        if privacySettings.excludeSensitiveHeaders || privacySettings.excludeRequestBody || privacySettings.excludeResponseBody {
            content += "\n--- Privacy Notice ---\n"
            content += "Some sensitive information has been excluded from this export for privacy reasons.\n"
        }
        
        return content
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
                .contextMenu {
                    Button("Copy") {
                        UIPasteboard.general.string = value
                    }
                }
        }
    }
}