import Foundation

@MainActor
class NetworkRequestService {
    
    // MARK: - Basic HTTP Methods
    
    func performGETRequest() async -> String {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return "Status: \(httpResponse.statusCode)"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    func performPOSTRequest() async -> String {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let postData = [
            "title": "Sample Post",
            "body": "This is a sample post body",
            "userId": 1
        ] as [String: Any]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: postData)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return "Status: \(httpResponse.statusCode)"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    func performPUTRequest() async -> String {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let putData = [
            "id": 1,
            "title": "Updated Post",
            "body": "This is an updated post body",
            "userId": 1
        ] as [String: Any]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: putData)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return "Status: \(httpResponse.statusCode)"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    func performDELETERequest() async -> String {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return "Status: \(httpResponse.statusCode)"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    // MARK: - Advanced Requests
    
    func performMultipleRequests() async -> String {
        let urls = [
            "https://jsonplaceholder.typicode.com/posts/1",
            "https://jsonplaceholder.typicode.com/posts/2",
            "https://jsonplaceholder.typicode.com/posts/3"
        ]
        
        let results = await withTaskGroup(of: Bool.self) { group in
            for urlString in urls {
                group.addTask {
                    let url = URL(string: urlString)!
                    do {
                        let _ = try await URLSession.shared.data(from: url)
                        return true
                    } catch {
                        return false
                    }
                }
            }
            
            var completedCount = 0
            for await _ in group {
                completedCount += 1
            }
            return completedCount
        }
        
        return "Completed \(results) requests"
    }
    
    func performMultipartPOSTRequest() async -> String {
        let url = URL(string: "https://httpbin.org/post")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add text field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
        body.append("Sample File Upload\r\n".data(using: .utf8)!)
        
        // Add another text field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n".data(using: .utf8)!)
        body.append("This is a multipart form data example\r\n".data(using: .utf8)!)
        
        // Add file field (simulated with text content)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"sample.txt\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/plain\r\n\r\n".data(using: .utf8)!)
        body.append("This is the content of the uploaded file.\nIt can contain multiple lines.\nLike this example.".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add JSON field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"metadata\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        
        let metadata: [String: Any] = [
            "userId": 123,
            "timestamp": Int(Date().timeIntervalSince1970),
            "version": "1.0"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata) {
            body.append(jsonData)
        }
        body.append("\r\n".data(using: .utf8)!)
        
        // Add binary data field (simulated)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"sample.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        
        // Simulate PNG header (not a real image)
        let pngHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        body.append(pngHeader)
        body.append("...simulated image data...".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return "Status: \(httpResponse.statusCode)"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    // MARK: - Media Downloads
    
    func performImageDownload() async -> String {
        let imageURL = URL(string: "https://picsum.photos/800/600")!
        var request = URLRequest(url: imageURL)
        request.setValue("image/jpeg,image/png,image/webp,image/*", forHTTPHeaderField: "Accept")
        request.setValue("NetworkUI-Example/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let sizeKB = Double(data.count) / 1024.0
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
                return "Downloaded \(String(format: "%.1f", sizeKB)) KB image (Status: \(httpResponse.statusCode), Type: \(contentType))"
            }
        } catch {
            return "Download Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    func performVideoDownload() async -> String {
        let videoURL = URL(string: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4")!
        var request = URLRequest(url: videoURL)
        request.setValue("video/mp4,video/*", forHTTPHeaderField: "Accept")
        request.setValue("NetworkUI-Example/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let sizeMB = Double(data.count) / (1024.0 * 1024.0)
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
                let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length") ?? "unknown"
                return "Downloaded \(String(format: "%.2f", sizeMB)) MB video (Status: \(httpResponse.statusCode), Type: \(contentType), Length: \(contentLength))"
            }
        } catch {
            return "Download Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    // MARK: - Error Tests
    
    func performNetworkErrorTest() async -> String {
        // Test with invalid URL/Host
        let invalidURL = URL(string: "https://invalid-host-that-does-not-exist-12345.com/api/test")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: invalidURL)
            if let httpResponse = response as? HTTPURLResponse {
                return "Unexpected success: \(httpResponse.statusCode)"
            }
        } catch {
            return "Network Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
    
    func performTimeoutTest() async -> String {
        // Test with very short timeout
        let url = URL(string: "https://httpbin.org/delay/10")! // 10 second delay
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0 // 2 second timeout
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return "Unexpected success: \(httpResponse.statusCode)"
            }
        } catch {
            return "Timeout Error: \(error.localizedDescription)"
        }
        
        return "Unknown error"
    }
}
