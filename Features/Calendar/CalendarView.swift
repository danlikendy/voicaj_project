import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var showingDatePicker = false
    
    enum CalendarViewMode: String, CaseIterable {
        case month = "Месяц"
        case week = "Неделя"
        case day = "День"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                calendarHeader
                
                // Calendar Content
                calendarContent
                
                Spacer()
            }
            .background(Color.porcelain)
            .navigationBarHidden(true)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 100 {
                            // Свайп вправо - предыдущий период
                            previousPeriod()
                        } else if value.translation.width < -100 {
                            // Свайп влево - следующий период
                            nextPeriod()
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.3), value: selectedDate)
        }
    }
    
    private func previousPeriod() {
        switch calendarViewMode {
        case .month:
            if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        case .week:
            if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        case .day:
            if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
    private func nextPeriod() {
        switch calendarViewMode {
        case .month:
            if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        case .week:
            if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        case .day:
            if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
    // MARK: - Calendar Header
    private var calendarHeader: some View {
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
            
            // Центр: месяц и год
            VStack(alignment: .center, spacing: 4) {
                Text(monthYearString)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.espresso)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Правая часть: меню выбора режима
            VStack(alignment: .trailing, spacing: 4) {
                Menu {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) {
                            calendarViewMode = mode
                        }
                    }
                } label: {
                    HStack {
                        Text(calendarViewMode.rawValue)
                            .foregroundColor(.espresso)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.tobacco)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.bone)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
        .cornerRadius(20)
    }
    
    // MARK: - Calendar Content
    @ViewBuilder
    private var calendarContent: some View {
        switch calendarViewMode {
        case .month:
            MonthCalendarView(selectedDate: $selectedDate)
        case .week:
            WeekCalendarView(selectedDate: $selectedDate)
        case .day:
            DayCalendarView(selectedDate: $selectedDate)
        }
    }
    
    // MARK: - Helper Properties
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: selectedDate)
        
        // Исправляем склонения месяцев
        let correctedMonth = correctMonthName(monthYear)
        return correctedMonth.capitalized
    }
    
    private func correctMonthName(_ monthYear: String) -> String {
        let month = monthYear.components(separatedBy: " ").first ?? monthYear
        
        let corrections = [
            "января": "январь",
            "февраля": "февраль", 
            "марта": "март",
            "апреля": "апрель",
            "мая": "май",
            "июня": "июнь",
            "июля": "июль",
            "августа": "август",
            "сентября": "сентябрь",
            "октября": "октябрь",
            "ноября": "ноябрь",
            "декабря": "декабрь"
        ]
        
        if let corrected = corrections[month] {
            return monthYear.replacingOccurrences(of: month, with: corrected)
        }
        
        return monthYear
    }
    
    // Статическая функция для использования в других структурах
    static func correctMonthName(_ monthYear: String) -> String {
        let month = monthYear.components(separatedBy: " ").first ?? monthYear
        
        let corrections = [
            "января": "январь",
            "февраля": "февраль", 
            "марта": "март",
            "апреля": "апрель",
            "мая": "май",
            "июня": "июнь",
            "июля": "июль",
            "августа": "август",
            "сентября": "сентябрь",
            "октября": "октябрь",
            "ноября": "ноябрь",
            "декабря": "декабрь"
        ]
        
        if let corrected = corrections[month] {
            return monthYear.replacingOccurrences(of: month, with: corrected)
        }
        
        return monthYear
    }
}

// MARK: - Month Calendar View
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    
        var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Days of week header
            daysOfWeekHeader
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            hasTasks: hasTasksForDate(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private var daysOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tobacco)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = (firstWeekday + 5) % 7 // Adjust for Monday start
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining cells to complete the grid
        let remainingCells = (7 - (days.count % 7)) % 7
        days += Array(repeating: nil, count: remainingCells)
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func hasTasksForDate(_ date: Date) -> Bool {
        // TODO: Implement task checking logic
        return false
    }
}

// MARK: - Week Calendar View
struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 0) {
            // Week header
            weekHeader
            
            // Week content
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(weekDays, id: \.self) { date in
                        WeekDayRow(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

        }
    }
    
    private var weekHeader: some View {
        HStack {
            Spacer()
            
            Text(weekRangeString)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.espresso)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        
        let start = weekDays.first ?? selectedDate
        let end = weekDays.last ?? selectedDate
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private func previousWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - Day Calendar View
struct DayCalendarView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header
            dayHeader
            
            // Day content
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(hourSlots, id: \.self) { hour in
                        HourSlotRow(hour: hour, date: selectedDate)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

        }
    }
    
    private var dayHeader: some View {
        HStack {
            Spacer()
            
            Text(dayString)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.espresso)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        let dayMonth = formatter.string(from: selectedDate)
        
        // Исправляем склонения месяцев
        let correctedDayMonth = CalendarView.correctMonthName(dayMonth)
        return correctedDayMonth.capitalized
    }
    
    private var hourSlots: [Int] {
        // Показываем только часы с 6 до 22, но можно расширить при необходимости
        Array(6...22)
    }
    
    private func previousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTasks: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
            
            // Task indicator
            if hasTasks {
                Circle()
                    .fill(Color.honeyGold)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 60)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(overlayColor, lineWidth: 3)
        )
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .honeyGold
        } else {
            return .espresso
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .honeyGold
        } else if isToday {
            return .honeyGold.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var overlayColor: Color {
        if isSelected {
            return .honeyGold
        } else {
            return .clear
        }
    }
}

// MARK: - Week Day Row
struct WeekDayRow: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(dayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.tobacco)
                
                Text(dayNumber)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.espresso)
            }
            
            Spacer()
            
            // Task preview (placeholder)
            VStack(alignment: .trailing, spacing: 4) {
                Text("0 задач")
                    .font(.system(size: 14))
                    .foregroundColor(.tobacco)
                
                // Progress indicator placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.honeyGold.opacity(0.3))
                    .frame(width: 40, height: 4)
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(overlayColor, lineWidth: 2)
        )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .honeyGold.opacity(0.1)
        } else if isToday {
            return .honeyGold.opacity(0.05)
        } else {
            return .porcelain
        }
    }
    
    private var overlayColor: Color {
        if isSelected {
            return .honeyGold
        } else if isToday {
            return .honeyGold.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized
    }
    
    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }
}

// MARK: - Hour Slot Row
struct HourSlotRow: View {
    let hour: Int
    let date: Date
    
    // TODO: Заменить на реальную проверку задач
    private var hasTasks: Bool {
        // Показываем только часы с 8 до 20 для демонстрации
        return hour >= 8 && hour <= 20
    }
    
    var body: some View {
        if hasTasks {
            HStack(spacing: 16) {
                Text(timeString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tobacco)
                    .frame(width: 50, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Placeholder for tasks at this hour
                    Text("Нет задач")
                        .font(.system(size: 14))
                        .foregroundColor(.tobacco)
                        .italic()
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.porcelain)
            .cornerRadius(8)
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        
        return formatter.string(from: hourDate)
    }
}

#Preview {
    CalendarView()
}
