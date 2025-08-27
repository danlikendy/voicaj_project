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
        .accentColor(.honeyGold)
        .preferredColorScheme(.light) // Принудительно используем светлую тему
        .onAppear {
            // Настройка внешнего вида TabBar для эффекта стекла согласно пункту 11
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.clear
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            
            // Добавляем закругления и тени
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)
            appearance.shadowImage = UIImage()
            
            // Настройка цветов согласно палитре пункта 11
            // Активное состояние: Honey Gold (#D4A574) - согласно брендбуку
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.honeyGold)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.honeyGold),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Неактивное состояние: Tobacco (#5B514A) - темнее для лучшей видимости
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.tobacco)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color.tobacco),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Настройка позиционирования иконок по центру
            // Убираем лишние отступы для центрирования
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Принудительно применяем стили
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let tabBar = windowScene.windows.first?.rootViewController?.tabBarController?.tabBar {
                    tabBar.standardAppearance = appearance
                    tabBar.scrollEdgeAppearance = appearance
                    tabBar.layer.cornerRadius = 20
                    tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    tabBar.clipsToBounds = true
                    
                    // Дополнительные настройки для центрирования
                    tabBar.itemPositioning = .centered
                    tabBar.itemSpacing = 0
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
