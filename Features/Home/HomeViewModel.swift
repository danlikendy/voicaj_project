import Foundation
import Combine
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var collapsedSections: Set<TaskStatus> = []
    @Published var isRecordingButtonPulsing = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupData()
        startPulsingAnimation()
    }
    
    // MARK: - Computed Properties
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: Date())
    }
    
    var currentDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: Date())
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Доброе утро"
        case 12..<17:
            return "Добрый день"
        case 17..<22:
            return "Добрый вечер"
        default:
            return "Доброй ночи"
        }
    }
    
    var currentStreak: Int {
        // TODO: Implement streak calculation based on voice records
        return 7
    }
    
    var recordingButtonText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour < 12 {
            return "Сделайте план на сегодня"
        } else {
            return "Запишите итог дня"
        }
    }
    
    var availableTags: [String] {
        let allTags = tasks.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    // MARK: - Public Methods
    
    func tasksForStatus(_ status: TaskStatus) -> [TaskItem] {
        return tasks.filter { $0.status == status }
    }
    
    func toggleSection(_ status: TaskStatus) {
        if collapsedSections.contains(status) {
            collapsedSections.remove(status)
        } else {
            collapsedSections.insert(status)
        }
    }
    
    func completeTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].status = .completed
            tasks[index].completedAt = Date()
            tasks[index].updatedAt = Date()
        }
    }
    
    func snoozeTask(_ task: TaskItem, until date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].dueDate = date
            tasks[index].updatedAt = Date()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }
    
    // MARK: - Private Methods
    
    private func setupData() {
        // TODO: Load tasks from data service
        loadSampleData()
    }
    
    private func startPulsingAnimation() {
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    self?.isRecordingButtonPulsing.toggle()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSampleData() {
        // Sample tasks for development
        let sampleTasks = [
            TaskItem(
                title: "Сделать уборку",
                description: "Пропылесосить и помыть полы",
                status: .completed,
                priority: .medium,
                tags: ["дом", "быт"],
                createdAt: Date().addingTimeInterval(-86400)
            ),
            TaskItem(
                title: "Купить продукты",
                description: "Молоко, хлеб, яйца",
                status: .planned,
                priority: .high,
                dueDate: Date().addingTimeInterval(3600),
                tags: ["покупки", "быт"]
            ),
            TaskItem(
                title: "Позвонить маме",
                description: "Узнать как дела",
                status: .important,
                priority: .high,
                tags: ["семья", "звонки"]
            ),
            TaskItem(
                title: "Записаться к врачу",
                description: "Терапевт, на следующей неделе",
                status: .stuck,
                priority: .medium,
                tags: ["здоровье", "врач"]
            ),
            TaskItem(
                title: "Изучить SwiftUI",
                description: "Новые возможности iOS 17",
                status: .idea,
                priority: .low,
                tags: ["разработка", "обучение"]
            )
        ]
        
        tasks = sampleTasks
    }
}
