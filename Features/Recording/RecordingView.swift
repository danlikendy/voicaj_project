import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Запись")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Здесь будет экран записи голоса")
                    .foregroundColor(.secondary)
                
                Button("Закрыть") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RecordingView()
}
