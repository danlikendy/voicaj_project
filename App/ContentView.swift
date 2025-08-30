import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(homeViewModel)
                .onAppear {
                    print("🏠 HomeView загружен")
                }
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
            
            ChatView(homeViewModel: homeViewModel)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Чат")
                }
        }
        .accentColor(.honeyGold)
        .preferredColorScheme(.light) // Принудительно используем светлую тему
        .onAppear {
            // Настройка внешнего вида TabBar в стиле верхнего меню
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(Color.porcelain).withAlphaComponent(0.8)
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            
            // Добавляем тени как в верхнем меню
            appearance.shadowColor = UIColor(Color.porcelain).withAlphaComponent(0.3)
            appearance.shadowImage = UIImage()
            
            // Настройка цветов согласно палитре
            // Активное состояние: Honey Gold (#D4A574)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.honeyGold)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.honeyGold),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            // Неактивное состояние: Tobacco (#5B514A)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.tobacco)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color.tobacco),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Принудительно применяем стили
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let tabBar = windowScene.windows.first?.rootViewController?.tabBarController?.tabBar {
                    tabBar.standardAppearance = appearance
                    tabBar.scrollEdgeAppearance = appearance
                    
                    // Убираем закругления - делаем как верхнее меню
                    tabBar.layer.cornerRadius = 0
                    tabBar.clipsToBounds = false
                    
                    // Добавляем тень как в верхнем меню
                    tabBar.layer.shadowColor = UIColor(Color.porcelain).cgColor
                    tabBar.layer.shadowOpacity = 0.3
                    tabBar.layer.shadowRadius = 8
                    tabBar.layer.shadowOffset = CGSize(width: 0, height: -4)
                    
                    // Добавляем размытую верхнюю границу
                    let topBorderLayer = CALayer()
                    topBorderLayer.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 20)
                    
                    let gradientLayer = CAGradientLayer()
                    gradientLayer.frame = topBorderLayer.bounds
                    gradientLayer.colors = [
                        UIColor(Color.porcelain).cgColor,
                        UIColor(Color.porcelain).withAlphaComponent(0.6).cgColor,
                        UIColor.clear.cgColor
                    ]
                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
                    
                    topBorderLayer.addSublayer(gradientLayer)
                    tabBar.layer.addSublayer(topBorderLayer)
                    
                    // Настройка позиционирования
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
