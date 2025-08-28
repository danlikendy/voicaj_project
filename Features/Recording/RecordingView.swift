import SwiftUI
import AVFoundation
import Speech

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.porcelain
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    recordingHeader
                    
                    // Main recording area
                    if viewModel.isRecording {
                        recordingArea
                    } else if viewModel.isProcessing {
                        processingArea
                    } else if viewModel.hasResults {
                        resultsArea
                    } else {
                        initialArea
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.requestPermissions()
        }
        .alert("Ошибка записи", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Header
    private var recordingHeader: some View {
        HStack {
            Button("Отмена") {
                dismiss()
            }
            .foregroundColor(.espresso)
            .font(.system(size: 17, weight: .medium))
            
            Spacer()
            
            if let template = viewModel.selectedTemplate {
                Text(template.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.espresso)
            }
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 60)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    // MARK: - Initial Area
    private var initialArea: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Main recording button
            Button(action: {
                viewModel.startRecording()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.honeyGold)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(viewModel.buttonScale)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.buttonScale)
            
            Text("Нажмите, чтобы начать запись")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.espresso)
                .multilineTextAlignment(.center)
            
            // Voice templates
            VStack(spacing: 16) {
                Text("Быстрые шаблоны")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.tobacco)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(VoiceTemplate.allCases, id: \.self) { template in
                        Button(action: {
                            viewModel.selectTemplate(template)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: template.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.honeyGold)
                                
                                Text(template.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.espresso)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.bone)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(viewModel.selectedTemplate == template ? Color.honeyGold : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Recording Area
    private var recordingArea: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Audio wave animation
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.honeyGold)
                        .frame(width: 4, height: viewModel.waveHeights[index])
                        .animation(.easeInOut(duration: 0.3), value: viewModel.waveHeights[index])
                }
            }
            .frame(height: 60)
            
            // Timer
            Text(viewModel.recordingTime)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.espresso)
                .monospacedDigit()
            
            // Live transcription
            if !viewModel.liveTranscription.isEmpty {
                VStack(spacing: 12) {
                    Text("Что я слышу:")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.tobacco)
                    
                    Text(viewModel.liveTranscription)
                        .font(.system(size: 16))
                        .foregroundColor(.espresso)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bone)
                        )
                }
            }
            
            // Recording controls
            HStack(spacing: 40) {
                Button(action: {
                    viewModel.pauseRecording()
                }) {
                    Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.cornflowerBlue)
                }
                
                Button(action: {
                    viewModel.stopRecording()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.terracotta)
                }
                
                Button(action: {
                    viewModel.cancelRecording()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.warmGrey)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Processing Area
    private var processingArea: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .honeyGold))
            
            Text("Обрабатываю запись...")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.espresso)
            
            Text("AI анализирует ваш голос и создает задачи")
                .font(.system(size: 16))
                .foregroundColor(.tobacco)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Results Area
    private var resultsArea: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Что я услышал")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.espresso)
                    
                    Text("AI проанализировал вашу запись и создал следующие задачи:")
                        .font(.system(size: 16))
                        .foregroundColor(.tobacco)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Tasks by blocks
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    if let tasks = viewModel.tasksByStatus[status], !tasks.isEmpty {
                        TaskBlockView(status: status, tasks: tasks) { task in
                            viewModel.editTask(task)
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button("Сохранить все") {
                        viewModel.saveAllTasks()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.honeyGold)
                    )
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))
                    
                    Button("Редактировать всё") {
                        viewModel.editAllTasks()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.honeyGold, lineWidth: 2)
                    )
                    .foregroundColor(.honeyGold)
                    .font(.system(size: 17, weight: .semibold))
                    
                    Button("Сделать шаблоном") {
                        viewModel.saveAsTemplate()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cornflowerBlue, lineWidth: 2)
                    )
                    .foregroundColor(.cornflowerBlue)
                    .font(.system(size: 17, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Task Block View
struct TaskBlockView: View {
    let status: TaskStatus
    let tasks: [TaskItem]
    let onEdit: (TaskItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(status.colorValue)
                    .frame(width: 12, height: 12)
                
                Text(status.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.tobacco)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.bone)
                    )
            }
            
            ForEach(tasks, id: \.id) { task in
                RecordingTaskRowView(task: task, onEdit: onEdit)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Recording Task Row View
struct RecordingTaskRowView: View {
    let task: TaskItem
    let onEdit: (TaskItem) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.espresso)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.tobacco)
                        .lineLimit(2)
                }
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.cornflowerBlue)
                        
                        Text(dueDate, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.cornflowerBlue)
                    }
                }
                
                if !task.tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.honeyGold)
                        
                        Text(task.tags.joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundColor(.honeyGold)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                onEdit(task)
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundColor(.honeyGold)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.bone)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bone.opacity(0.5))
        )
    }
}

#Preview {
    RecordingView()
}
