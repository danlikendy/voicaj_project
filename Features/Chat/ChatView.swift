import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Чат")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Здесь будет чат с AI-ассистентом")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Чат")
        }
    }
}

#Preview {
    ChatView()
}
