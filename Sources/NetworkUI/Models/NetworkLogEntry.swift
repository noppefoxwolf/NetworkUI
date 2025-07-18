import Foundation
import SwiftData

@Model
public class NetworkLogEntry {
    public var id: UUID
    public var timestamp: Date
    public var method: String
    public var url: String
    public var requestHeaders: [String: String]
    public var requestBody: Data?
    public var responseStatusCode: Int?
    public var responseHeaders: [String: String]?
    public var responseBody: Data?
    public var duration: TimeInterval?
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), method: String, url: String, requestHeaders: [String: String] = [:], requestBody: Data? = nil, responseStatusCode: Int? = nil, responseHeaders: [String: String]? = nil, responseBody: Data? = nil, duration: TimeInterval? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.url = url
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.responseStatusCode = responseStatusCode
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.duration = duration
    }
    
    // Media type detection
    public var contentType: String? {
        return responseHeaders?["Content-Type"] ?? responseHeaders?["content-type"]
    }
    
    public var isImage: Bool {
        guard let contentType = contentType else { return false }
        return contentType.hasPrefix("image/")
    }
    
    public var isVideo: Bool {
        guard let contentType = contentType else { return false }
        return contentType.hasPrefix("video/")
    }
    
    public var isAudio: Bool {
        guard let contentType = contentType else { return false }
        return contentType.hasPrefix("audio/")
    }
    
    public var isMedia: Bool {
        return isImage || isVideo || isAudio
    }
    
    public var mediaType: MediaType? {
        if isImage { return .image }
        if isVideo { return .video }
        if isAudio { return .audio }
        return nil
    }
    
    public var fileSizeFormatted: String? {
        guard let data = responseBody else { return nil }
        let bytes = Double(data.count)
        
        if bytes < 1024 {
            return "\(Int(bytes)) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        } else {
            return String(format: "%.1f GB", bytes / (1024 * 1024 * 1024))
        }
    }
}

public enum MediaType: String, CaseIterable {
    case image = "Image"
    case video = "Video"
    case audio = "Audio"
    
    public var systemImage: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "music.note"
        }
    }
}