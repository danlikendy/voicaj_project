import SwiftUI

struct TimelineView: View {
    @State private var searchText = ""
    @State private var selectedFilter: TimelineFilter? = nil

    
    // Демо-данные для отображения структуры
    private let demoDays = [
        TimelineDay(
            date: Date(),
            progress: 0.8,
            mood: .positive,
            tags: ["работа", "спорт", "быт"],
            keyTasks: [
                TimelineTask(title: "Завершить проект", status: .completed, color: .mossGreen),
                TimelineTask(title: "Тренировка", status: .completed, color: .terracotta),
                TimelineTask(title: "Уборка", status: .inProgress, color: .honeyGold)
            ],
            totalTasks: 5,
            completedTasks: 4
        ),
        TimelineDay(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            progress: 0.6,
            mood: .neutral,
            tags: ["работа", "обучение"],
            keyTasks: [
                TimelineTask(title: "Изучить SwiftUI", status: .completed, color: .cornflowerBlue),
                TimelineTask(title: "Встреча с командой", status: .inProgress, color: .cornflowerBlue),
                TimelineTask(title: "Планирование недели", status: .planned, color: .warmGrey)
            ],
            totalTasks: 3,
            completedTasks: 2
        ),
        TimelineDay(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            progress: 0.4,
            mood: .stressed,
            tags: ["быт", "здоровье"],
            keyTasks: [
                TimelineTask(title: "Поход к врачу", status: .completed, color: .teal),
                TimelineTask(title: "Покупки", status: .overdue, color: .olive),
                TimelineTask(title: "Уборка", status: .overdue, color: .mint)
            ],
            totalTasks: 3,
            completedTasks: 1
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer для заголовка
                        Color.clear
                            .frame(height: 90)
                        
                        // Фильтры
                        filterSection
                        
                        // Отступ между хештегами и контентом
                        Color.clear
                            .frame(height: 16)
                        
                        // Основная лента
                        timelineContent
                        
                        // Дополнительный отступ внизу для красивого UI
                        Color.clear
                            .frame(height: 20)
                    }
                    .background(Color.porcelain)
                }
                .background(Color.porcelain)
                
                // Закрепленный заголовок
                VStack(spacing: 0) {
                    // Заголовок с поиском
                    searchHeader
                        .ignoresSafeArea(edges: .top)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header с поиском
    private var searchHeader: some View {
        HStack {
            // Поиск
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.tobacco)
                    .font(.system(size: 16))
                
                TextField("Поиск по записям, тегам, задачам...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.tobacco)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.bone)
            .cornerRadius(20)
            .shadow(color: Color.porcelain.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 80)
        .padding(.bottom, 16)
        .background(Color.porcelain)
        .cornerRadius(0)
        .shadow(color: Color.porcelain.opacity(0.3), radius: 8, x: 0, y: 4)

    }
    
    // MARK: - Секция фильтров (хештеги) - точно как на вкладке Дом
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimelineFilter.allCases, id: \.self) { filter in
                    HomeFilterChip(
                        tag: filter.title,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedFilter == filter {
                                selectedFilter = nil
                            } else {
                                selectedFilter = nil
                                selectedFilter = filter
                            }
                        }
                    }
                }
            }
        }
        .mask(
            HStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
                
                Rectangle()
                    .fill(Color.black)
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
            }
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Основной контент таймлайна
    private var timelineContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(demoDays.indices, id: \.self) { index in
                let day = demoDays[index]
                TimelineDayCard(day: day)
            }
            
            // Кнопка "Загрузить еще"
            Button(action: {}) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 18))
                    Text("Загрузить еще")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.honeyGold)
                .padding(.vertical, 16)
            }
            
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Модели данных
struct TimelineDay {
    let date: Date
    let progress: Double
    let mood: MoodType
    let tags: [String]
    let keyTasks: [TimelineTask]
    let totalTasks: Int
    let completedTasks: Int
}

struct TimelineTask {
    let title: String
    let status: TimelineTaskStatus
    let color: Color
}

enum MoodType {
    case positive, neutral, stressed
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .neutral: return "😐"
        case .stressed: return "😰"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .mossGreen
        case .neutral: return .warmGrey
        case .stressed: return .terracotta
        }
    }
}

enum TimelineTaskStatus {
    case completed, inProgress, planned, overdue
}

enum TimelineFilter: CaseIterable {
    case completed, inProgress, overdue
    
    var title: String {
        switch self {
        case .completed: return "выполнено"
        case .inProgress: return "в работе"
        case .overdue: return "просрочено"
        }
    }
}



struct TimelineDayCard: View {
    let day: TimelineDay
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Заголовок дня
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.espresso)
                    
                    Text(progressText)
                        .font(.system(size: 14))
                        .foregroundColor(.tobacco)
                }
                
                Spacer()
                
                // Прогресс кольцо
                ZStack {
                    Circle()
                        .stroke(Color.porcelain, lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: day.progress)
                        .stroke(day.mood.color, lineWidth: 4)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: day.progress)
                    
                    Text("\(Int(day.progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.espresso)
                }
            }
            
            // Настроение и теги
            HStack {
                // Настроение
                HStack(spacing: 8) {
                    Text(day.mood.emoji)
                        .font(.system(size: 20))
                    
                    Text(moodText)
                        .font(.system(size: 14))
                        .foregroundColor(.tobacco)
                }
                
                Spacer()
                
                // Теги
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(day.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.honeyGold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.honeyGold.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .mask(
                    HStack(spacing: 0) {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 20)
                        
                        Rectangle()
                            .fill(Color.black)
                        
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black, Color.clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 20)
                    }
                )
            }
            
            // Ключевые задачи
            VStack(spacing: 8) {
                ForEach(day.keyTasks.prefix(isExpanded ? day.keyTasks.count : 3), id: \.title) { task in
                    HStack {
                        Circle()
                            .fill(task.color)
                            .frame(width: 8, height: 8)
                        
                        Text(task.title)
                            .font(.system(size: 14))
                            .foregroundColor(.espresso)
                        
                        Spacer()
                        
                        Text(statusText(for: task.status))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor(for: task.status))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.porcelain)
                    .cornerRadius(8)
                }
                
                // Кнопка "Показать еще" если задач больше 3
                if day.keyTasks.count > 3 {
                    Button(action: { isExpanded.toggle() }) {
                        HStack {
                            Text(isExpanded ? "Скрыть" : "Показать еще \(day.keyTasks.count - 3)")
                                .font(.system(size: 14, weight: .medium))
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.honeyGold)
                    }
                }
            }
            
            // Кнопки действий
            HStack(spacing: 12) {
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 16))
                        Text("Слушать")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.honeyGold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.honeyGold.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                        Text("Детали дня")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.espresso)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.porcelain)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Вспомогательные свойства
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: day.date).capitalized
    }
    
    private var progressText: String {
        "\(day.completedTasks) из \(day.totalTasks) задач выполнено"
    }
    
    private var moodText: String {
        switch day.mood {
        case .positive: return "Позитивное"
        case .neutral: return "Нейтральное"
        case .stressed: return "Напряженное"
        }
    }
    
    private func statusText(for status: TimelineTaskStatus) -> String {
        switch status {
        case .completed: return "Выполнено"
        case .inProgress: return "В работе"
        case .planned: return "Запланировано"
        case .overdue: return "Просрочено"
        }
    }
    
    private func statusColor(for status: TimelineTaskStatus) -> Color {
        switch status {
        case .completed: return .mossGreen
        case .inProgress: return .honeyGold
        case .planned: return .cornflowerBlue
        case .overdue: return .terracotta
        }
    }
}



#Preview {
    TimelineView()
}
