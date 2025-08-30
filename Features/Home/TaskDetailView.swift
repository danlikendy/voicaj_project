import SwiftUI

import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: SimpleTaskManager
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerView
                    
                    // Description
                    if let description = task.description {
                        descriptionView(description)
                    }
                    
                    // Metadata
                    metadataView
                    
                    // Actions
                    actionsView
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color.bone)
            .navigationTitle("Детали задачи")
            .navigationBarTitleDisplayMode(.large)

        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(task.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.espresso)
            
            // Status and Priority
            HStack(spacing: 16) {
                // Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(ColorPalette.statusColor(for: task.status))
                        .frame(width: 12, height: 12)
                    
                    Text(task.status.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.espresso)
                }
                
                // Priority
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(ColorPalette.priorityColor(for: task.priority))
                    
                    Text(task.priority.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.espresso)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
        .cornerRadius(16)
    }
    
    // MARK: - Description View
    private func descriptionView(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Описание")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.espresso)
            
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(.tobacco)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
        .cornerRadius(16)
    }
    
    // MARK: - Metadata View
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Информация")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.espresso)
            
            VStack(spacing: 12) {
                // Due Date
                if task.dueDate != nil {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.tobacco)
                            .frame(width: 20)
                        
                        Text("Срок выполнения:")
                            .foregroundColor(.tobacco)
                        
                        Spacer()
                        
                        Text(task.formattedDueDate)
                            .foregroundColor(task.isOverdue ? .red : .espresso)
                            .fontWeight(.medium)
                    }
                }
                
                // Tags
                if !task.tags.isEmpty {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.tobacco)
                            .frame(width: 20)
                        
                        Text("Теги:")
                            .foregroundColor(.tobacco)
                        
                        Spacer()
                        
                        Text(task.tags.joined(separator: ", "))
                            .foregroundColor(.espresso)
                            .fontWeight(.medium)
                    }
                }
                
                // Created Date
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.tobacco)
                        .frame(width: 20)
                    
                    Text("Создано:")
                        .foregroundColor(.tobacco)
                    
                    Spacer()
                    
                                            Text(formatDate(task.updatedAt))
                            .foregroundColor(.espresso)
                            .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
        .cornerRadius(16)
    }
    
    // MARK: - Actions View
    private var actionsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingEditSheet = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Редактировать")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.honeyGold)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Удалить")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.terracotta)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TaskEditView(task: task, taskManager: taskManager)
                .presentationDetents([.large, .medium])
        }
        .alert("Удалить задачу?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                taskManager.deleteTask(task)
                print("🗑️ Удаление задачи: \(task.title)")
                dismiss()
            }
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TaskDetailView(
        task: TaskItem(
            title: "Sample Task",
            description: "This is a sample task description",
            status: .planned,
            priority: .high,
            tags: ["sample", "test"]
        ),
        taskManager: SimpleTaskManager()
    )
}
