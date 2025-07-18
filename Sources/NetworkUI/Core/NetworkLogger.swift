import Foundation
import SwiftData

@Observable
@MainActor
public class NetworkLogger {
    public static let shared = NetworkLogger()
    
    // Privacy settings
    public var privacySettings = PrivacySettings()
    
    // Persistence settings
    public var isPersistenceEnabled = true
    
    private let dataManager = NetworkUIDataManager.shared
    
    private init() {}
    
    public func log(_ entry: NetworkLogEntry) {
        if isPersistenceEnabled {
            dataManager.add(entry)
        }
    }
    
    public func clearLogs() {
        dataManager.deleteAll()
    }
    
    public var modelContext: ModelContext {
        dataManager.context
    }
}

public struct PrivacySettings {
    public var excludeSensitiveHeaders: Bool = true
    public var excludeRequestBody: Bool = false
    public var excludeResponseBody: Bool = false
    public var sensitiveHeaderKeys: Set<String> = [
        "Authorization",
        "Cookie",
        "Set-Cookie",
        "X-Auth-Token",
        "X-API-Key",
        "Bearer",
        "X-Session-ID",
        "X-CSRF-Token",
        "X-Access-Token",
        "X-Refresh-Token"
    ]
    
    public init() {}
    
    public mutating func addSensitiveHeader(_ key: String) {
        sensitiveHeaderKeys.insert(key.lowercased())
    }
    
    public mutating func removeSensitiveHeader(_ key: String) {
        sensitiveHeaderKeys.remove(key.lowercased())
    }
    
    public func shouldExcludeHeader(_ key: String) -> Bool {
        guard excludeSensitiveHeaders else { return false }
        return sensitiveHeaderKeys.contains(key.lowercased())
    }
    
    public func filteredHeaders(_ headers: [String: String]) -> [String: String] {
        guard excludeSensitiveHeaders else { return headers }
        return headers.filter { key, _ in
            !shouldExcludeHeader(key)
        }
    }
}