import Foundation
import SwiftData

@MainActor
public class NetworkUIDataManager {
    public static let shared = NetworkUIDataManager()
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private init() {
        let schema = Schema([NetworkLogEntry.self])
        let modelConfiguration = ModelConfiguration(
            "NetworkUILogs",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            modelContext = modelContainer.mainContext
        } catch {
            // If migration fails, reset the database
            print("NetworkUI: Failed to create ModelContainer, resetting database: \(error)")
            
            do {
                // Delete existing database file
                let url = URL.applicationSupportDirectory.appending(path: "NetworkUILogs.sqlite")
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
                
                // Create new container
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                modelContext = modelContainer.mainContext
                
                print("NetworkUI: Database reset successfully")
            } catch {
                fatalError("Failed to reset NetworkUI database: \(error)")
            }
        }
    }
    
    public var context: ModelContext {
        modelContext
    }
    
    public func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save NetworkUI data: \(error)")
        }
    }
    
    public func deleteAll() {
        do {
            try modelContext.delete(model: NetworkLogEntry.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all NetworkUI logs: \(error)")
        }
    }
    
    public func deleteOldLogs(keepingLatest count: Int) {
        let fetchDescriptor = FetchDescriptor<NetworkLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let allLogs = try modelContext.fetch(fetchDescriptor)
            let logsToDelete = allLogs.dropFirst(count)
            
            for log in logsToDelete {
                modelContext.delete(log)
            }
            
            if !logsToDelete.isEmpty {
                try modelContext.save()
            }
        } catch {
            print("Failed to delete old logs: \(error)")
        }
    }
    
    public func add(_ entry: NetworkLogEntry) {
        modelContext.insert(entry)
        
        // Auto-save and cleanup
        Task {
            await MainActor.run {
                save()
                deleteOldLogs(keepingLatest: 1000)
            }
        }
    }
}