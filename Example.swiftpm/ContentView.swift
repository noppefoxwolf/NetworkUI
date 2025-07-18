import SwiftUI
import NetworkUI

struct ContentView: View {
    @State private var logger = NetworkLogger.shared
    @State private var isLoading = false
    @State private var responseMessage = ""
    @State private var showingNetworkLogs = false
    
    private let requestService = NetworkRequestService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Status section
                        VStack(spacing: 12) {
                            if isLoading {
                                ProgressView("Loading...")
                                    .padding()
                            }
                            
                            if !responseMessage.isEmpty {
                                Text("Last Response: \(responseMessage)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // HTTP Methods Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HTTP Methods")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                RequestButton(title: "GET", color: .blue, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performGETRequest()
                                    }
                                }
                                
                                RequestButton(title: "POST", color: .green, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performPOSTRequest()
                                    }
                                }
                                
                                RequestButton(title: "PUT", color: .orange, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performPUTRequest()
                                    }
                                }
                                
                                RequestButton(title: "DELETE", color: .red, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performDELETERequest()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Advanced Tests Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Advanced Tests")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 10) {
                                RequestButton(title: "Multipart POST", color: .blue, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performMultipartPOSTRequest()
                                    }
                                }
                                
                                RequestButton(title: "Multiple Requests", color: .blue, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performMultipleRequests()
                                    }
                                }
                                
                                RequestButton(title: "Download Image", color: .purple, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performImageDownload()
                                    }
                                }
                                
                                RequestButton(title: "Download Video", color: .indigo, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performVideoDownload()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Error Tests Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Error Tests")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                RequestButton(title: "Network Error", color: .red, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performNetworkErrorTest()
                                    }
                                }
                                
                                RequestButton(title: "Timeout", color: .orange, isLoading: isLoading) {
                                    performRequest {
                                        await requestService.performTimeoutTest()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Fixed Bottom Button
                VStack {
                    Divider()
                    Button("View Network Logs") {
                        showingNetworkLogs = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Network Sample")
            .onAppear {
                NetworkInterceptor.register()
            }
            .sheet(isPresented: $showingNetworkLogs) {
                NetworkLogView()
            }
        }
    }
    
    private func performRequest(_ action: @escaping () async -> String) {
        Task {
            isLoading = true
            responseMessage = ""
            responseMessage = await action()
            isLoading = false
        }
    }
}