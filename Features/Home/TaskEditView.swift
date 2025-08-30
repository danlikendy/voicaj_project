import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: SimpleTaskManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedStatus: TaskStatus = .planned
    @State private var selectedPriority: TaskPriority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    let task: TaskItem?
    let isEditing: Bool
    
    init(task: TaskItem? = nil, taskManager: SimpleTaskManager) {
        self.task = task
        self.isEditing = task != nil
        self.taskManager = taskManager
        
        if let task = task {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description ?? "")
            _selectedStatus = State(initialValue: task.status)
            _selectedPriority = State(initialValue: task.priority)
            _dueDate = State(initialValue: task.dueDate ?? Date())
            _hasDueDate = State(initialValue: task.dueDate != nil)
            _tags = State(initialValue: task.tags)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Основная информация
                Section("Основная информация") {
                    TextField("Название задачи", text: $title)
                        .foregroundColor(.espresso)
                    
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(.espresso)
                }
                
                // Статус и приоритет
                Section("Статус и приоритет") {
                    Picker("Статус", selection: $selectedStatus) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            HStack {
                                Circle()
                                    .fill(ColorPalette.statusColor(for: status))
                                    .frame(width: 12, height: 12)
                                Text(status.displayName)
                                    .foregroundColor(.espresso)
                            }
                            .tag(status)
                        }
                    }
                    
                    Picker("Приоритет", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(ColorPalette.priorityColor(for: priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName)
                                    .foregroundColor(.espresso)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                // Срок выполнения
                Section("Срок выполнения") {
                    Toggle("Установить срок", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Срок", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                // Теги
                Section("Теги") {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack {
                                Text("#\(tag)")
                                    .foregroundColor(.honeyGold)
                                
                                Spacer()
                                
                                Button(action: {
                                    tags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.terracotta)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Добавить тег", text: $newTag)
                            .foregroundColor(.espresso)
                        
                        Button("Добавить") {
                            if !newTag.isEmpty && !tags.contains(newTag) {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                        .foregroundColor(newTag.isEmpty ? .tobacco : .honeyGold)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bone)
            .navigationTitle(isEditing ? "Редактировать задачу" : "Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.terracotta)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveTask()
                    }
                    .foregroundColor(.honeyGold)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        if isEditing, let existingTask = task {
            // Обновляем существующую задачу
            var updatedTask = existingTask
            updatedTask.title = title
            updatedTask.description = description.isEmpty ? nil : description
            updatedTask.status = selectedStatus
            updatedTask.priority = selectedPriority
            updatedTask.dueDate = hasDueDate ? dueDate : nil
            updatedTask.tags = tags
            updatedTask.updatedAt = Date()
            
            taskManager.updateTask(updatedTask)
            print("✅ Обновлена задача: \(updatedTask.title)")
        } else {
            // Создаем новую задачу
            let newTask = TaskItem(
                title: title,
                description: description.isEmpty ? nil : description,
                status: selectedStatus,
                priority: selectedPriority,
                dueDate: hasDueDate ? dueDate : nil,
                tags: tags,
                isPrivate: false,
                audioURL: nil,
                transcript: nil,
                createdAt: Date(),
                updatedAt: Date(),
                completedDate: nil,
                parentTaskId: nil,
                subtasks: []
            )
            
            taskManager.addTask(newTask)
            print("✅ Создана задача: \(newTask.title)")
        }
        
        dismiss()
    }
}

#Preview {
    TaskEditView(taskManager: SimpleTaskManager())
}
