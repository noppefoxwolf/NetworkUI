import SwiftUI

struct RequestButton: View {
    let title: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle")
                }
            }
            .padding()
            .foregroundColor(.white)
            .background(color.opacity(isLoading ? 0.6 : 1.0))
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        RequestButton(title: "GET Request", color: .blue, isLoading: false) {
            print("GET tapped")
        }
        
        RequestButton(title: "Loading...", color: .green, isLoading: true) {
            print("Loading tapped")
        }
        
        RequestButton(title: "Error Test", color: .red, isLoading: false) {
            print("Error tapped")
        }
    }
    .padding()
}