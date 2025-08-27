import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "saved_tasks"
    
    init() {
        loadTasks()
    }
    
    // MARK: - CRUD Operations
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.updatedAt = Date()
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            if updatedTask.status == .completed {
                updatedTask.status = .planned
                updatedTask.completedAt = nil
            } else {
                updatedTask.status = .completed
                updatedTask.completedAt = Date()
            }
            updatedTask.updatedAt = Date()
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func moveTask(_ task: TaskItem, to status: TaskStatus) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.status = status
            updatedTask.updatedAt = Date()
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    // MARK: - Task Queries
    
    func tasksForStatus(_ status: TaskStatus) -> [TaskItem] {
        return tasks.filter { $0.status == status }
    }
    
    func tasksForDate(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    func overdueTasks() -> [TaskItem] {
        let now = Date()
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate < now && task.status != .completed
            }
            return false
        }
    }
    
    func tasksWithTag(_ tag: String) -> [TaskItem] {
        return tasks.filter { task in
            task.tags.contains { $0.lowercased().contains(tag.lowercased()) }
        }
    }
    
    // MARK: - Statistics
    
    var totalTasks: Int {
        return tasks.count
    }
    
    var completedTasks: Int {
        return tasks.filter { $0.status == .completed }.count
    }
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var tasksByStatus: [TaskStatus: Int] {
        var result: [TaskStatus: Int] = [:]
        for status in TaskStatus.allCases {
            result[status] = tasks.filter { $0.status == status }.count
        }
        return result
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: tasksKey)
        } catch {
            self.error = "Ошибка сохранения задач: \(error.localizedDescription)"
        }
    }
    
    private func loadTasks() {
        guard let data = userDefaults.data(forKey: tasksKey) else { return }
        
        do {
            let loadedTasks = try JSONDecoder().decode([TaskItem].self, from: data)
            tasks = loadedTasks
        } catch {
            self.error = "Ошибка загрузки задач: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sample Data
    
    func addSampleTasks() {
        let sampleTasks = [
            TaskItem(
                title: "Уборка в доме",
                description: "Помыть посуду, пропылесосить",
                status: .completed,
                priority: .medium,
                tags: ["дом", "быт"]
            ),
            TaskItem(
                title: "Позвонить маме",
                description: "Узнать как дела",
                status: .planned,
                priority: .high,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                tags: ["семья", "важно"]
            ),
            TaskItem(
                title: "Записаться к врачу",
                description: "Проверить здоровье",
                status: .planned,
                priority: .medium,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                tags: ["здоровье"]
            )
        ]
        
        for task in sampleTasks {
            addTask(task)
        }
    }
    
    func clearAllTasks() {
        tasks.removeAll()
        saveTasks()
    }
}
