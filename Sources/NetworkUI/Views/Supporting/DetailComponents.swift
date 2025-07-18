import SwiftUI

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CopyableText: View {
    let content: String
    let label: String?
    
    init(content: String, label: String? = nil) {
        self.content = content
        self.label = label
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(content)
                .font(.body)
                .textSelection(.enabled)
                .onLongPressGesture(minimumDuration: 0.5) {
                    UIPasteboard.general.string = content
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

struct CopyableHeaderView: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(key):")
                .bold()
                .font(.caption)
                .foregroundColor(.blue)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
                .onLongPressGesture(minimumDuration: 0.5) {
                    UIPasteboard.general.string = "\(key): \(value)"
                }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct CopyableCodeBlock: View {
    let content: String
    
    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onLongPressGesture(minimumDuration: 0.5) {
                    UIPasteboard.general.string = content
                }
        }
        .frame(maxHeight: 200)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}