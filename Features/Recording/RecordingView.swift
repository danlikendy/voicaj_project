import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioService = AudioRecordingService()
    @StateObject private var aiService = AIAnalysisService()
    
    @State private var transcript = ""
    @State private var showingResults = false
    @State private var aiResult: AIAnalysisResult?
    @State private var selectedTemplate: VoiceTemplate?
    @State private var showingTemplatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main Content
                if showingResults {
                    resultsView
                } else {
                    recordingView
                }
            }
            .background(Color.porcelain)
            .navigationBarHidden(true)
        }
        .onAppear {
            requestPermissions()
        }
        .alert("Ошибка", isPresented: Binding(
            get: { audioService.error != nil },
            set: { _ in audioService.error = nil }
        )) {
            Button("OK") {
                audioService.error = nil
            }
        } message: {
            Text(audioService.error ?? "")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button("Отмена") {
                if audioService.isRecording {
                    audioService.cancelRecording()
                }
                dismiss()
            }
            .foregroundColor(.espresso)
            .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            if let template = selectedTemplate {
                Text(template.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.tobacco)
            }
            
            Spacer()
            
            Button("Шаблон") {
                showingTemplatePicker = true
            }
            .foregroundColor(.cornflowerBlue)
            .font(.system(size: 16, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
    }
    
    // MARK: - Recording View
    
    private var recordingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Audio Waveform
            AudioWaveformView(
                audioLevel: audioService.audioLevel,
                isRecording: audioService.isRecording,
                isPaused: audioService.isPaused
            )
            .frame(height: 80)
            
            // Timer
            Text(formatDuration(audioService.recordingDuration))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.espresso)
            
            // Live Transcript
            if !transcript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Транскрипция")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.tobacco)
                    
                    Text(transcript)
                        .font(.system(size: 16))
                        .foregroundColor(.espresso)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.linen)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Recording Controls
            recordingControlsView
            
            // Tips
            if audioService.isRecording {
                recordingTipsView
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Recording Controls
    
    private var recordingControlsView: some View {
        HStack(spacing: 40) {
            // Pause/Resume Button
            Button(action: {
                if audioService.isPaused {
                    audioService.resumeRecording()
                } else {
                    audioService.pauseRecording()
                }
            }) {
                Image(systemName: audioService.isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.honeyGold)
            }
            .disabled(!audioService.isRecording)
            
            // Main Record/Stop Button
            Button(action: {
                if audioService.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(audioService.isRecording ? Color.terracotta : Color.cornflowerBlue)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: audioService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            // Cancel Button
            Button(action: {
                audioService.cancelRecording()
                transcript = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.tobacco)
            }
            .disabled(!audioService.isRecording)
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Recording Tips
    
    private var recordingTipsView: some View {
        VStack(spacing: 8) {
            Text("💡 Советы по диктовке")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.tobacco)
            
            Text("Говорите короткими предложениями")
                .font(.system(size: 12))
                .foregroundColor(.tobacco)
            
            Text("Используйте «завтра», «послезавтра» для сроков")
                .font(.system(size: 12))
                .foregroundColor(.tobacco)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Что я услышал")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.espresso)
                    
                    if let result = aiResult {
                        HStack(spacing: 8) {
                            Text(result.mood.emoji)
                                .font(.system(size: 20))
                            
                            Text("Настроение: \(result.mood.displayName)")
                                .font(.system(size: 16))
                                .foregroundColor(.tobacco)
                        }
                    }
                }
                .padding(.top, 20)
                
                // AI Analysis Progress
                if aiService.isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView(value: aiService.analysisProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .cornflowerBlue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text("Анализирую голос...")
                            .font(.system(size: 16))
                            .foregroundColor(.tobacco)
                    }
                    .padding(.horizontal, 40)
                }
                
                // Results
                if let result = aiResult {
                    // Tasks by Status
                    LazyVStack(spacing: 16) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            let tasksForStatus = result.tasks.filter { $0.status == status }
                            if !tasksForStatus.isEmpty {
                                TaskResultsSection(
                                    status: status,
                                    tasks: tasksForStatus
                                )
                            }
                        }
                    }
                    
                    // Action Buttons
                    actionButtonsView
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button("Сохранить") {
                saveRecording()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cornflowerBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .semibold))
            
            Button("Редактировать всё") {
                // TODO: Implement edit mode
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.linen)
            .foregroundColor(.espresso)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .medium))
            
            Button("Сделать шаблоном") {
                // TODO: Implement template creation
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.linen)
            .foregroundColor(.espresso)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .medium))
        }
        .padding(.top, 20)
    }
    
    // MARK: - Private Methods
    
    private func requestPermissions() {
        // Запрос разрешений на микрофон и распознавание речи
        // уже происходит в AudioRecordingService
    }
    
    private func startRecording() {
        transcript = ""
        audioService.startRecording()
        
        // Для демонстрации добавляем тестовую транскрипцию
        // В реальном приложении это будет приходить от Speech Recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if audioService.isRecording {
                transcript = "Сегодня сделал уборку в доме, купил продукты. Завтра нужно позвонить маме и записаться к врачу. Важно не забыть оплатить счета."
            }
        }
    }
    
    private func stopRecording() {
        guard let audioURL = audioService.stopRecording() else { return }
        
        // Анализируем запись с помощью AI
        Task {
            let result = await aiService.analyzeVoiceRecording(
                transcript: transcript,
                template: selectedTemplate
            )
            
            await MainActor.run {
                aiResult = result
                showingResults = true
            }
        }
    }
    
    private func saveRecording() {
        // TODO: Save recording and tasks to data store
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Task Results Section

struct TaskResultsSection: View {
    let status: TaskStatus
    let tasks: [Task]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(ColorPalette.statusColor(for: status))
                    .frame(width: 12, height: 12)
                
                Text(status.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Spacer()
                
                Text("(\(tasks.count))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.tobacco)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(tasks) { task in
                    TaskResultRow(task: task)
                }
            }
        }
        .padding(16)
        .background(Color.linen)
        .cornerRadius(12)
    }
}

// MARK: - Task Result Row

struct TaskResultRow: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.espresso)
                
                Spacer()
                
                if task.priority != .medium {
                    Circle()
                        .fill(ColorPalette.priorityColor(for: task.priority))
                        .frame(width: 8, height: 8)
                }
            }
            
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.tobacco)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.tobacco)
                        
                        Text(task.formattedDueDate)
                            .font(.system(size: 12))
                            .foregroundColor(.tobacco)
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
                    }
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color.porcelain)
        .cornerRadius(8)
    }
}

// MARK: - Template Picker Sheet

struct TemplatePickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedTemplate: VoiceTemplate?
    
    var body: some View {
        NavigationView {
            List(VoiceTemplate.allCases, id: \.self) { template in
                Button(action: {
                    selectedTemplate = template
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: template.icon)
                            .foregroundColor(.cornflowerBlue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.espresso)
                            
                            Text(template.description)
                                .font(.system(size: 14))
                                .foregroundColor(.tobacco)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Выберите шаблон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct UIRectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = UIRectCorner(rawValue: 1 << 0)
    static let topRight = UIRectCorner(rawValue: 1 << 1)
    static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    
    static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

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
    RecordingView()
}
