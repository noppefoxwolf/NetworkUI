import SwiftUI
import SwiftData

enum FilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case method = "Method"
    case domain = "Domain"
    case statusCode = "Status Code"
    case mediaType = "Media Type"
    
    var id: String { rawValue }
}

public struct NetworkLogView: View {
    public init() {}
    
    public var body: some View {
        NetworkLogContentView()
            .environment(\.modelContext, NetworkUIDataManager.shared.context)
    }
}

private struct NetworkLogContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logger = NetworkLogger.shared
    @State private var selectedLog: NetworkLogEntry?
    @State private var searchText = ""
    @State private var showingClearAlert = false
    @State private var showingFilters = false
    @State private var showingPrivacySettings = false
    @State private var selectedFilterType: FilterType = .all
    @State private var selectedMethod: String = "All"
    @State private var selectedDomain: String = "All"
    @State private var selectedStatusCode: String = "All"
    @State private var selectedMediaType: String = "All"
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \NetworkLogEntry.timestamp, order: .reverse) 
    private var allLogs: [NetworkLogEntry]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Status Bar
                if isFiltering {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .foregroundColor(.blue)
                            Text("Filters active")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button("Clear") {
                            clearFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                }
                
                // Main Content
                Group {
                    if filteredLogs.isEmpty {
                        ContentUnavailableView(
                            allLogs.isEmpty ? "No Network Requests" : "No Results",
                            systemImage: allLogs.isEmpty ? "network" : "magnifyingglass",
                            description: Text(allLogs.isEmpty ? "Make a network request to see logs appear here" : "Try adjusting your search or filter settings")
                        )
                    } else {
                        List(filteredLogs) { log in
                            NetworkLogRowView(log: log)
                                .onTapGesture {
                                    selectedLog = log
                                }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Network Logs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search requests...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(isFiltering ? .blue : .primary)
                        }
                        
                        Menu {
                            ShareLink(item: exportLogsText(), preview: SharePreview("Network Logs", image: Image(systemName: "network"))) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Button("Privacy Settings") {
                                showingPrivacySettings = true
                            }
                            
                            Divider()
                            
                            Button("Clear All", role: .destructive) {
                                showingClearAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Clear All Logs", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    logger.clearLogs()
                }
            } message: {
                Text("This will permanently delete all network logs.")
            }
        }
        .sheet(item: $selectedLog) { log in
            NetworkLogDetailView(log: log)
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(
                availableMethods: availableMethods,
                availableDomains: availableDomains,
                availableStatusCodes: availableStatusCodes,
                availableMediaTypes: availableMediaTypes,
                selectedMethod: $selectedMethod,
                selectedDomain: $selectedDomain,
                selectedStatusCode: $selectedStatusCode,
                selectedMediaType: $selectedMediaType
            )
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
    }
    
    private var availableMethods: [String] {
        let methods = Set(allLogs.map { $0.method })
        return ["All"] + methods.sorted()
    }
    
    private var availableDomains: [String] {
        let domains = Set(allLogs.compactMap { log in
            if let url = URL(string: log.url) {
                return url.host ?? "Unknown"
            }
            return nil
        })
        return ["All"] + domains.sorted()
    }
    
    private var availableStatusCodes: [String] {
        let codes = Set(allLogs.compactMap { log in
            log.responseStatusCode?.description
        })
        return ["All"] + codes.sorted()
    }
    
    private var availableMediaTypes: [String] {
        let types = Set(allLogs.compactMap { log in
            log.mediaType?.rawValue
        })
        return ["All"] + types.sorted()
    }
    
    private var filteredLogs: [NetworkLogEntry] {
        var logs = allLogs
        
        // Apply search filter
        if !searchText.isEmpty {
            logs = logs.filter { log in
                log.url.localizedCaseInsensitiveContains(searchText) ||
                log.method.localizedCaseInsensitiveContains(searchText) ||
                (log.responseStatusCode?.description.contains(searchText) ?? false)
            }
        }
        
        // Apply method filter
        if selectedMethod != "All" {
            logs = logs.filter { $0.method == selectedMethod }
        }
        
        // Apply domain filter
        if selectedDomain != "All" {
            logs = logs.filter { log in
                if let url = URL(string: log.url) {
                    return url.host == selectedDomain
                }
                return false
            }
        }
        
        // Apply status code filter
        if selectedStatusCode != "All" {
            logs = logs.filter { log in
                log.responseStatusCode?.description == selectedStatusCode
            }
        }
        
        // Apply media type filter
        if selectedMediaType != "All" {
            logs = logs.filter { log in
                log.mediaType?.rawValue == selectedMediaType
            }
        }
        
        return logs
    }
    
    private var isFiltering: Bool {
        selectedMethod != "All" || selectedDomain != "All" || selectedStatusCode != "All" || selectedMediaType != "All"
    }
    
    private func exportLogsText() -> String {
        var content = "=== Network Logs Export ===\n\n"
        content += "Generated: \(Date())\n"
        content += "Total Requests: \(allLogs.count)\n"
        
        let privacySettings = logger.privacySettings
        if privacySettings.excludeSensitiveHeaders {
            content += "Note: Sensitive headers have been excluded for privacy\n"
        }
        if privacySettings.excludeRequestBody {
            content += "Note: Request bodies have been excluded for privacy\n"
        }
        if privacySettings.excludeResponseBody {
            content += "Note: Response bodies have been excluded for privacy\n"
        }
        content += "\n"
        
        for (index, log) in allLogs.enumerated() {
            content += "[\(index + 1)] \(log.method) \(log.url)\n"
            content += "Time: \(log.timestamp)\n"
            if let statusCode = log.responseStatusCode {
                content += "Status: \(statusCode)\n"
            }
            if let duration = log.duration {
                content += "Duration: \(String(format: "%.3f", duration))s\n"
            }
            
            // Request Headers
            let requestHeaders = privacySettings.filteredHeaders(log.requestHeaders)
            if !requestHeaders.isEmpty {
                content += "Request Headers:\n"
                for (key, value) in requestHeaders.sorted(by: { $0.key < $1.key }) {
                    content += "  \(key): \(value)\n"
                }
            }
            
            // Request Body
            if let requestBody = log.requestBody, !privacySettings.excludeRequestBody {
                content += "Request Body: \(String(data: requestBody, encoding: .utf8) ?? "Binary data")\n"
            }
            
            // Response Headers
            if let responseHeaders = log.responseHeaders {
                let filteredResponseHeaders = privacySettings.filteredHeaders(responseHeaders)
                if !filteredResponseHeaders.isEmpty {
                    content += "Response Headers:\n"
                    for (key, value) in filteredResponseHeaders.sorted(by: { $0.key < $1.key }) {
                        content += "  \(key): \(value)\n"
                    }
                }
            }
            
            // Response Body
            if let responseBody = log.responseBody, !privacySettings.excludeResponseBody {
                content += "Response Body: \(String(data: responseBody, encoding: .utf8) ?? "Binary data")\n"
            }
            
            content += "\n"
        }
        
        return content
    }
    
    private func clearFilters() {
        selectedMethod = "All"
        selectedDomain = "All"
        selectedStatusCode = "All"
        selectedMediaType = "All"
    }
}

struct FilterView: View {
    let availableMethods: [String]
    let availableDomains: [String]
    let availableStatusCodes: [String]
    let availableMediaTypes: [String]
    @Binding var selectedMethod: String
    @Binding var selectedDomain: String
    @Binding var selectedStatusCode: String
    @Binding var selectedMediaType: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("HTTP Method") {
                    ForEach(availableMethods, id: \.self) { method in
                        HStack {
                            Text(method)
                                .foregroundColor(method == "All" ? .secondary : methodColor(method))
                            Spacer()
                            if method == selectedMethod {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMethod = method
                        }
                    }
                }
                
                Section("Domain") {
                    ForEach(availableDomains, id: \.self) { domain in
                        HStack {
                            Text(domain)
                                .foregroundColor(domain == "All" ? .secondary : .primary)
                            Spacer()
                            if domain == selectedDomain {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDomain = domain
                        }
                    }
                }
                
                Section("Status Code") {
                    ForEach(availableStatusCodes, id: \.self) { code in
                        HStack {
                            Text(code)
                                .foregroundColor(code == "All" ? .secondary : statusCodeColor(Int(code) ?? 0))
                            Spacer()
                            if code == selectedStatusCode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedStatusCode = code
                        }
                    }
                }
                
                Section("Media Type") {
                    ForEach(availableMediaTypes, id: \.self) { mediaType in
                        HStack {
                            if mediaType != "All", let type = MediaType(rawValue: mediaType) {
                                Image(systemName: type.systemImage)
                                    .foregroundColor(.purple)
                            }
                            Text(mediaType)
                                .foregroundColor(mediaType == "All" ? .secondary : .purple)
                            Spacer()
                            if mediaType == selectedMediaType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMediaType = mediaType
                        }
                    }
                }
            }
            .navigationTitle("Filter Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All", role: .destructive) {
                        selectedMethod = "All"
                        selectedDomain = "All"
                        selectedStatusCode = "All"
                        selectedMediaType = "All"
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
    
    private func statusCodeColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .orange
        case 400..<500: return .red
        case 500..<600: return .purple
        default: return .gray
        }
    }
}
