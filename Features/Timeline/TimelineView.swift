import SwiftUI

struct TimelineView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Таймлайн")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Здесь будет лента записей и дней")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Таймлайн")
        }
    }
}

#Preview {
    TimelineView()
}
