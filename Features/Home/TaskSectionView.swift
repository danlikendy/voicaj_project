import SwiftUI

struct TaskSectionView: View {
    let status: TaskStatus
    let tasks: [TaskItem]
    let isCollapsed: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: onToggle) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(ColorPalette.statusColor(for: status))
                            .frame(width: 12, height: 12)
                        
                        Text(status.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.espresso)
                        
                        Text("(\(tasks.count))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.tobacco)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.tobacco)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.porcelain)
                .cornerRadius(16, corners: [.topLeft, .topRight])
            }
            .buttonStyle(PlainButtonStyle())
            
            // Section Content
            if !isCollapsed && !tasks.isEmpty {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        TaskRowView(task: task)
                        
                        if task.id != tasks.last?.id {
                            Divider()
                                .background(Color.parchment)
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color.porcelain)
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
            } else if !isCollapsed && tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.honeyGold)
                    
                    Text("Нет задач в этом разделе")
                        .font(.system(size: 14))
                        .foregroundColor(.tobacco)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.porcelain)
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
            }
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @State private var showingTaskDetail = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox - отдельная кнопка
            Button(action: {
                // TODO: Complete task
                print("✅ Отметить задачу выполненной: \(task.title)")
            }) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.status == .completed ? ColorPalette.statusColor(for: .completed) : .tobacco)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Основная область задачи - кликабельна полностью
            Button(action: {
                showingTaskDetail = true
            }) {
                HStack(spacing: 0) {
                    // Task Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(task.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.espresso)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Priority indicator
                            if task.priority != .medium {
                                Circle()
                                    .fill(ColorPalette.priorityColor(for: task.priority))
                                    .frame(width: 8, height: 8)
                            }
                            
                            // Private indicator
                            if task.isPrivate {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.tobacco)
                            }
                        }
                        
                        if let description = task.description {
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundColor(.tobacco)
                                .lineLimit(1)
                        }
                        
                        // Task metadata
                        HStack(spacing: 12) {
                            if task.dueDate != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 12))
                                        .foregroundColor(.tobacco)
                                    
                                    Text(task.formattedDueDate)
                                        .font(.system(size: 12))
                                        .foregroundColor(task.isOverdue ? .red : .tobacco)
                                }
                            }
                            
                            if !task.tags.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.tobacco)
                                    
                                    Text(task.tags.joined(separator: ", "))
                                        .font(.system(size: 12))
                                        .foregroundColor(.tobacco)
                                        .lineLimit(1)
                                }
                            }
                            
                            if task.audioURL != nil {
                                Image(systemName: "waveform")
                                    .font(.system(size: 12))
                                    .foregroundColor(.tobacco)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Status indicator
                    Circle()
                        .fill(ColorPalette.statusColor(for: task.status))
                        .frame(width: 12, height: 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task)
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

import UIKit

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 16) {
        TaskSectionView(
            status: .planned,
            tasks: [
                TaskItem(title: "Sample Task 1", description: "Description 1"),
                TaskItem(title: "Sample Task 2", description: "Description 2")
            ],
            isCollapsed: false
        ) {}
        
        TaskSectionView(
            status: .completed,
            tasks: [],
            isCollapsed: false
        ) {}
    }
    .padding()
    .background(Color.bone)
}
