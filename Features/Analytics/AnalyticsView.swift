import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Аналитика")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Здесь будет аналитика продуктивности")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Аналитика")
        }
    }
}

#Preview {
    AnalyticsView()
}
