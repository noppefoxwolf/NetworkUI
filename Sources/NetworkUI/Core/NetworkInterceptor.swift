import Foundation

public class NetworkInterceptor: URLProtocol {
    @MainActor
    private static var isRegistered = false
    
    @MainActor
    public static func register() {
        guard !isRegistered else { return }
        URLProtocol.registerClass(NetworkInterceptor.self)
        isRegistered = true
    }
    
    @MainActor
    public static func unregister() {
        guard isRegistered else { return }
        URLProtocol.unregisterClass(NetworkInterceptor.self)
        isRegistered = false
    }
    
    private var startTime: Date?
    private var dataTask: URLSessionDataTask?
    
    override public func startLoading() {
        startTime = Date()
        
        let config = URLSessionConfiguration.default
        config.protocolClasses = []
        let session = URLSession(configuration: config)
        
        dataTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            let endTime = Date()
            let duration = self.startTime.map { endTime.timeIntervalSince($0) }
            
            let entry = NetworkLogEntry(
                method: self.request.httpMethod ?? "GET",
                url: self.request.url?.absoluteString ?? "",
                requestHeaders: self.request.allHTTPHeaderFields ?? [:],
                requestBody: self.request.httpBody,
                responseStatusCode: (response as? HTTPURLResponse)?.statusCode,
                responseHeaders: (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] ?? [:],
                responseBody: data,
                duration: duration
            )
            
            Task { @MainActor in
                NetworkLogger.shared.log(entry)
            }
            
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = response {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        dataTask?.resume()
    }
    
    override public func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
    
    override public class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
}
