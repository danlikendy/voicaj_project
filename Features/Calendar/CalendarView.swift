import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Календарь")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Здесь будет календарь с задачами")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Календарь")
        }
    }
}

#Preview {
    CalendarView()
}
