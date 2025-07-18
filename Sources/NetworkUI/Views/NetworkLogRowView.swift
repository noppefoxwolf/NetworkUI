import SwiftUI

struct NetworkLogRowView: View {
    let log: NetworkLogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.method)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(methodColor)
                    .cornerRadius(4)
                
                // Media type indicator
                if log.isMedia, let mediaType = log.mediaType {
                    HStack(spacing: 4) {
                        Image(systemName: mediaType.systemImage)
                        Text(mediaType.rawValue)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.purple)
                    .cornerRadius(4)
                }
                
                Spacer()
                
                // File size for media
                if log.isMedia, let fileSize = log.fileSizeFormatted {
                    Text(fileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let statusCode = log.responseStatusCode {
                    Text("\(statusCode)")
                        .font(.caption)
                        .foregroundColor(statusCodeColor(statusCode))
                }
                
                if let duration = log.duration {
                    Text("\(String(format: "%.3f", duration))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(log.url)
                    .font(.body)
                    .lineLimit(2)
                
                Spacer()
                
                // Media preview icon
                if log.isMedia {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            
            Text(log.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var methodColor: Color {
        switch log.method {
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