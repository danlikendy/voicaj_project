import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var selectedPeriod: AnalyticsPeriod = .week
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showingAIReport = false


    
    enum AnalyticsPeriod: String, CaseIterable {
        case day = "День"
        case week = "Неделя"
        case month = "Месяц"
        case year = "Год"
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Spacer для заголовка
                        Color.clear
                            .frame(height: 44)
                        
                        // KPI Cards
                        kpiCardsSection
                        
                        // Charts
                        chartsSection
                        
                        // AI Insights
                        aiInsightsSection
                        
                        // Дополнительный отступ внизу для красивого UI
                        Color.clear
                            .frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color.porcelain)
                
                // Закрепленный заголовок поверх всего контента
                VStack(spacing: 0) {
                    // Заголовок с кнопками
                    analyticsHeader
                        .ignoresSafeArea(edges: .top)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Analytics Header
    private var analyticsHeader: some View {
        HStack {
            // Левая часть: кнопка "Сегодня"
            Button("Сегодня") {
                selectedDate = Date()
            }
            .foregroundColor(.espresso)
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.bone)
            .cornerRadius(8)
            
            Spacer()
            
            // Правая часть: кнопка с календарем
            Button(action: {
                showingDatePicker = true
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.tobacco)
                        .font(.system(size: 16))
                    Text("Выбрать дату")
                        .foregroundColor(.espresso)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.bone)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 80)
        .padding(.bottom, 16)
        .background(Color.porcelain)
        .cornerRadius(0)
        .shadow(color: Color.porcelain.opacity(0.3), radius: 8, x: 0, y: 4)

    }
    
    // MARK: - KPI Cards Section
    private var kpiCardsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Ключевые показатели")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                KPICard(
                    title: "Выполнено задач",
                    value: "24",
                    change: "+12%",
                    isPositive: true,
                    icon: "checkmark.circle.fill",
                    color: .mossGreen
                )
                
                KPICard(
                    title: "Продуктивность",
                    value: "87%",
                    change: "+5%",
                    isPositive: true,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .honeyGold
                )
                
                KPICard(
                    title: "Голосовые записи",
                    value: "18",
                    change: "+8",
                    isPositive: true,
                    icon: "mic.fill",
                    color: .cornflowerBlue
                )
                
                KPICard(
                    title: "Средний балл",
                    value: "4.2",
                    change: "-0.3",
                    isPositive: false,
                    icon: "star.fill",
                    color: .terracotta
                )
            }
        }

    }
    
    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Тренды")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Spacer()
            }
            
            // Productivity Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Продуктивность по дням")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.espresso)
                
                Chart {
                    ForEach(productivityData, id: \.date) { item in
                        LineMark(
                            x: .value("День", item.date),
                            y: .value("Продуктивность", item.value)
                        )
                        .foregroundStyle(Color.honeyGold)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("День", item.date),
                            y: .value("Продуктивность", item.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.honeyGold.opacity(0.3), Color.honeyGold.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            Text("\(value.as(Double.self)?.formatted(.number) ?? "")%")
                                .font(.system(size: 12))
                                .foregroundColor(.tobacco)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.weekday(.abbreviated))
                                    .font(.system(size: 12))
                                    .foregroundColor(.tobacco)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.bone)
            .cornerRadius(16)
        }

    }
    
    // MARK: - AI Insights Section
    private var aiInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI-анализ")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Spacer()
                
                Button("Подробнее") {
                    showingAIReport = true
                }
                .foregroundColor(.honeyGold)
                .font(.system(size: 14, weight: .medium))
            }
            
            VStack(spacing: 12) {
                AIInsightCard(
                    title: "Пик продуктивности",
                    description: "Вы наиболее эффективны с 9:00 до 11:00 утра",
                    icon: "sun.max.fill",
                    color: .honeyGold
                )
                
                AIInsightCard(
                    title: "Рекомендация",
                    description: "Попробуйте планировать сложные задачи на утренние часы",
                    icon: "lightbulb.fill",
                    color: .cornflowerBlue
                )
                
                AIInsightCard(
                    title: "Тренд",
                    description: "Ваша продуктивность выросла на 15% за последнюю неделю",
                    icon: "arrow.up.right",
                    color: .mossGreen
                )
            }
        }

        .sheet(isPresented: $showingAIReport) {
            AIReportView()
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
    }
    

    
    // MARK: - Demo Data
    private var productivityData: [ProductivityData] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let value = Double.random(in: 60...95)
            return ProductivityData(date: date, value: value)
        }.reversed()
    }
}

// MARK: - Supporting Views
struct KPICard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                
                Spacer()
                
                Text(change)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isPositive ? .mossGreen : .terracotta)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (isPositive ? Color.mossGreen : Color.terracotta).opacity(0.1)
                    )
                    .cornerRadius(8)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.espresso)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.tobacco)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bone)
        .cornerRadius(16)
    }
}

struct AIInsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.tobacco)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.bone)
        .cornerRadius(16)
    }
}

// MARK: - Data Models
struct ProductivityData {
    let date: Date
    let value: Double
}

// MARK: - AI Report View
struct AIReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // AI Report Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(.honeyGold)
                        
                        Text("AI-отчет по продуктивности")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.espresso)
                            .multilineTextAlignment(.center)
                        
                        Text("Анализ вашей эффективности за последний период")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.tobacco)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Detailed Insights
                    VStack(spacing: 16) {
                        Text("Ключевые выводы")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.espresso)
                        
                        VStack(spacing: 12) {
                            InsightRow(
                                icon: "clock.fill",
                                title: "Оптимальное время работы",
                                description: "9:00 - 11:00 и 14:00 - 16:00"
                            )
                            
                            InsightRow(
                                icon: "calendar.badge.plus",
                                title: "Лучшие дни недели",
                                description: "Вторник и четверг"
                            )
                            
                            InsightRow(
                                icon: "chart.bar.fill",
                                title: "Типы задач",
                                description: "Творческие задачи лучше выполнять утром"
                            )
                            
                            InsightRow(
                                icon: "target",
                                title: "Рекомендации",
                                description: "Увеличьте количество коротких перерывов"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.bone)
                    .cornerRadius(16)
                    
                    // Action Items
                    VStack(spacing: 16) {
                        Text("План действий")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.espresso)
                        
                        VStack(spacing: 12) {
                            ActionItemRow(
                                icon: "1.circle.fill",
                                text: "Планируйте сложные задачи на 9:00-11:00"
                            )
                            
                            ActionItemRow(
                                icon: "2.circle.fill",
                                text: "Делайте 5-минутные перерывы каждый час"
                            )
                            
                            ActionItemRow(
                                icon: "3.circle.fill",
                                text: "Используйте голосовые заметки для быстрых идей"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.bone)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.porcelain)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.honeyGold)
                }
            }
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.honeyGold)
                .font(.system(size: 20))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.tobacco)
            }
            
            Spacer()
        }
    }
}

struct ActionItemRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.mossGreen)
                .font(.system(size: 20))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.espresso)
            
            Spacer()
        }
    }
}

// MARK: - Date Picker View
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var pickerMode: PickerMode = .fullDate
    
    // MARK: - Date Range Logic
    
    /// Генерирует доступные годы для выбора (от 2020 до 2030)
    private var availableYears: [Int] {
        return Array(2020...2030)
    }
    
    /// Генерирует доступные месяцы для выбранного года
    private func availableMonths(for year: Int) -> [Int] {
        return Array(1...12)
    }
    
    /// Генерирует доступные дни для выбранного года и месяца
    private func availableDays(for year: Int, month: Int) -> [Int] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return Array(1...31)
        }
        return Array(1...(range.upperBound - 1))
    }
    
    /// Возвращает русское название месяца
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.monthSymbols[month - 1]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фон всего экрана
                Color.porcelain
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundColor(.honeyGold)
                        
                        Text("Выберите дату")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.espresso)
                            .multilineTextAlignment(.center)
                        
                        Text("Выберите режим выбора даты")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.tobacco)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Mode Selection
                    VStack(spacing: 16) {
                        Text("Режим выбора:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.espresso)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            ModeToggleButton(
                                title: "Год",
                                isSelected: pickerMode == .year,
                                action: { pickerMode = .year }
                            )
                            
                            ModeToggleButton(
                                title: "Месяц",
                                isSelected: pickerMode == .month,
                                action: { pickerMode = .month }
                            )
                            
                            ModeToggleButton(
                                title: "Полная дата",
                                isSelected: pickerMode == .fullDate,
                                action: { pickerMode = .fullDate }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Date Picker with Custom Components
                    Group {
                        if pickerMode == .year {
                            // Только год - такая же высота как у других режимов
                            Picker("Год", selection: $selectedDate) {
                                ForEach(availableYears, id: \.self) { year in
                                    Text("\(year)")
                                        .font(.system(size: 20, weight: .medium))
                                        .tag(Calendar.current.date(from: DateComponents(year: year)) ?? Date())
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 200)
                        } else if pickerMode == .month {
                            // Месяц и год - правильный порядок как в полной дате
                            HStack(spacing: 20) {
                                // Месяц (сначала)
                                Picker("Месяц", selection: $selectedDate) {
                                    ForEach(availableMonths(for: Calendar.current.component(.year, from: selectedDate)), id: \.self) { month in
                                        Text(monthName(for: month))
                                            .font(.system(size: 20, weight: .medium))
                                            .tag(Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: selectedDate), month: month)) ?? Date())
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .frame(width: 140)
                                
                                // Год (потом)
                                Picker("Год", selection: $selectedDate) {
                                    ForEach(availableYears, id: \.self) { year in
                                        Text("\(year)")
                                            .font(.system(size: 20, weight: .medium))
                                            .tag(Calendar.current.date(from: DateComponents(year: year)) ?? Date())
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .frame(width: 100)
                            }
                        } else {
                            // Полная дата - кастомный DatePicker с русскими месяцами
                            HStack(spacing: 20) {
                                // День
                                Picker("День", selection: $selectedDate) {
                                    ForEach(availableDays(for: Calendar.current.component(.year, from: selectedDate), month: Calendar.current.component(.month, from: selectedDate)), id: \.self) { day in
                                        Text("\(day)")
                                            .font(.system(size: 20, weight: .medium))
                                            .tag(Calendar.current.date(from: DateComponents(
                                                year: Calendar.current.component(.year, from: selectedDate),
                                                month: Calendar.current.component(.month, from: selectedDate),
                                                day: day
                                            )) ?? Date())
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .frame(width: 80)
                                
                                // Месяц (русский)
                                Picker("Месяц", selection: $selectedDate) {
                                    ForEach(availableMonths(for: Calendar.current.component(.year, from: selectedDate)), id: \.self) { month in
                                        Text(monthName(for: month))
                                            .font(.system(size: 20, weight: .medium))
                                            .tag(Calendar.current.date(from: DateComponents(
                                                year: Calendar.current.component(.year, from: selectedDate),
                                                month: month,
                                                day: Calendar.current.component(.day, from: selectedDate)
                                            )) ?? Date())
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .frame(width: 140)
                                
                                // Год
                                Picker("Год", selection: $selectedDate) {
                                    ForEach(availableYears, id: \.self) { year in
                                        Text("\(year)")
                                            .font(.system(size: 20, weight: .medium))
                                            .tag(Calendar.current.date(from: DateComponents(
                                                year: year,
                                                month: Calendar.current.component(.month, from: selectedDate),
                                                day: Calendar.current.component(.day, from: selectedDate)
                                            )) ?? Date())
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .frame(width: 100)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.3), value: pickerMode)
                    
                    // Action Button
                    Button("Выбрать") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.honeyGold)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Picker Mode
enum PickerMode: CaseIterable {
    case year, month, fullDate
    
    var components: [DatePickerComponents] {
        switch self {
        case .year:
            return [.date]
        case .month:
            return [.date]
        case .fullDate:
            return [.date]
        }
    }
    
    var description: String {
        switch self {
        case .year:
            return "Только год"
        case .month:
            return "Год и месяц"
        case .fullDate:
            return "Полная дата"
        }
    }
}

// MARK: - Mode Toggle Button
struct ModeToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .espresso)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.honeyGold : Color.bone)
                .cornerRadius(8)
        }
    }
}



#Preview {
    AnalyticsView()
}
