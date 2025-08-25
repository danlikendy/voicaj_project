import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Дом")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Календарь")
                }
            
            TimelineView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Таймлайн")
                }
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Аналитика")
                }
            
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Чат")
                }
        }
        .accentColor(.accentColor)
    }
}

#Preview {
    ContentView()
}
