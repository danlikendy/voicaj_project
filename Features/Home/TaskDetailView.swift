import SwiftUI
import AVFoundation

struct TaskDetailView: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: SimpleTaskManager
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAudioPlayer = false
    @State private var showingTranscript = false
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackProgress: Double = 0.0
    
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
                    
                    // Audio and Transcript (if available)
                    if task.tags.contains("голосовая-запись") {
                        audioSection
                    }
                    
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
    
    // MARK: - Audio Section
    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Голосовая запись")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.espresso)
            
            VStack(spacing: 12) {
                // Audio Player Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingAudioPlayer.toggle()
                    }
                    if isPlaying {
                        stopAudio()
                    } else {
                        playAudio()
                    }
                }) {
                    HStack {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.terracotta)
                        
                        Text(isPlaying ? "Пауза" : "Прослушать запись")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.espresso)
                        
                        Spacer()
                        
                        Image(systemName: showingAudioPlayer ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.espresso)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                
                // Audio Player (if expanded)
                if showingAudioPlayer {
                    VStack(spacing: 8) {
                        // Progress Bar
                        ProgressView(value: playbackProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .terracotta))
                        
                        HStack {
                            Text(formatTime(audioPlayer?.currentTime ?? 0))
                                .font(.caption)
                                .foregroundColor(.espresso)
                            
                            Spacer()
                            
                            Text(formatTime(audioPlayer?.duration ?? 0))
                                .font(.caption)
                                .foregroundColor(.espresso)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // Transcript Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingTranscript.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 20))
                            .foregroundColor(.terracotta)
                        
                        Text("Показать транскрипцию")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.espresso)
                        
                        Spacer()
                        
                        Image(systemName: showingTranscript ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.espresso)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                
                // Transcript (if expanded)
                if showingTranscript {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Транскрипция:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.espresso)
                        
                        Text("Мне до конца завтрашнего дня нужно будет сходить в деканат поэтому поставь задачу на 14")
                            .font(.system(size: 14))
                            .foregroundColor(.espresso)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Audio Functions
    private func playAudio() {
        // Создаем тестовый аудио файл (в реальном приложении здесь будет URL записи)
        guard let audioURL = createTestAudioFile() else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = AudioPlayerDelegate { [self] in
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.playbackProgress = 0.0
                }
            }
            audioPlayer?.play()
            isPlaying = true
            
            // Симулируем прогресс воспроизведения
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                guard let player = self.audioPlayer else {
                    timer.invalidate()
                    return
                }
                
                if player.isPlaying {
                    self.playbackProgress = player.currentTime / player.duration
                } else {
                    timer.invalidate()
                    self.isPlaying = false
                }
            }
        } catch {
            print("Ошибка воспроизведения аудио: \(error)")
        }
    }
    
    private func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
        playbackProgress = 0.0
    }
    
    private func createTestAudioFile() -> URL? {
        // Создаем тестовый аудио файл для демонстрации
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("test_audio.m4a")
        
        // Если файл уже существует, возвращаем его
        if FileManager.default.fileExists(atPath: audioURL.path) {
            return audioURL
        }
        
        // Создаем короткий тестовый аудио файл
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 44100)!
        
        // Заполняем буфер тестовыми данными (тишина)
        audioBuffer.frameLength = 44100
        
        do {
            let audioFile = try AVAudioFile(forWriting: audioURL, settings: audioFormat.settings)
            try audioFile.write(from: audioBuffer)
            return audioURL
        } catch {
            print("Ошибка создания тестового аудио: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Player Delegate
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        completion()
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
