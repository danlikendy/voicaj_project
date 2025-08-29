import Foundation
import Combine
import SwiftUI
import AVFoundation
import Speech

class HomeViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var collapsedSections: Set<TaskStatus> = []
    @Published var isRecordingButtonPulsing = true
    
    // MARK: - Recording States
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordingStartTime: Date?
    @Published var waveHeights: [CGFloat] = Array(repeating: 0.3, count: 20)
    
    private var cancellables = Set<AnyCancellable>()
    private var recordingTimer: Timer?
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    init() {
        setupData()
        startPulsingAnimation()
        setupSpeechRecognition()
    }
    
    // MARK: - Speech Recognition Setup
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        // Не создаем audioEngine здесь - создадим только когда понадобится
    }
    
    // MARK: - Recording Methods
    func startRecording() {
        guard !isRecording else { return }
        
        print("🎤 Запуск записи...")
        
        // Сначала запрашиваем разрешение на микрофон
        requestMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            
            print("🎤 Разрешение на микрофон: \(granted)")
            
            if granted {
                // Затем запрашиваем разрешение на распознавание речи
                self.requestSpeechRecognitionPermission { speechGranted in
                    print("🎯 Разрешение на распознавание речи: \(speechGranted)")
                    
                    DispatchQueue.main.async {
                        if speechGranted {
                            // Создаем audioEngine только после получения разрешений
                            self.audioEngine = AVAudioEngine()
                            
                            // Настраиваем аудиосессию только после получения разрешений
                            self.setupAudioSession { success in
                                if success {
                                    print("✅ Аудиосессия настроена успешно")
                                    self.isRecording = true
                                    self.recordingStartTime = Date()
                                    self.recordingTime = 0
                                    self.startRecordingTimer()
                                    self.setupWaveAnimation()
                                    self.startAudioRecording()
                                    self.startSpeechRecognition()
                                } else {
                                    print("❌ Не удалось настроить аудиосессию")
                                }
                            }
                        } else {
                            print("❌ Разрешение на распознавание речи не получено")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("❌ Разрешение на микрофон не получено")
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.stopRecordingTimer()
            self.stopAudioRecording()
            self.stopSpeechRecognition()
            
            // Создаем задачу на основе записи
            self.createTaskFromRecording()
        }
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func setupWaveAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                for i in 0..<self.waveHeights.count {
                    self.waveHeights[i] = CGFloat.random(in: 0.1...1.0)
                }
            }
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            // Используем новый API для iOS 17.0+
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    print("🎤 Результат запроса разрешения на микрофон (iOS 17+): \(granted)")
                    completion(granted)
                }
            }
        } else {
            // Fallback для старых версий iOS
            let audioSession = AVAudioSession.sharedInstance()
            let currentStatus = audioSession.recordPermission
            
            print("🔍 Текущий статус разрешения на микрофон (legacy): \(currentStatus.rawValue)")
            
            switch currentStatus {
            case .granted:
                print("✅ Разрешение на микрофон уже получено")
                completion(true)
            case .denied:
                print("❌ Разрешение на микрофон отклонено")
                completion(false)
            case .undetermined:
                print("❓ Разрешение на микрофон не определено, запрашиваем...")
                audioSession.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        print("🎤 Результат запроса разрешения на микрофон: \(granted)")
                        completion(granted)
                    }
                }
            @unknown default:
                print("❓ Неизвестный статус разрешения на микрофон")
                completion(false)
            }
        }
    }
    
    private func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                let granted = status == .authorized
                completion(granted)
            }
        }
    }
    
    private func setupAudioSession(completion: @escaping (Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            print("🔧 Настройка аудиосессии...")
            
            // Проверяем статус разрешения (используем современный API если доступен)
            if #available(iOS 17.0, *) {
                print("🔧 Статус разрешения на запись (iOS 17+): используем современный API")
            } else {
                let permissionStatus = audioSession.recordPermission
                print("🔧 Статус разрешения на запись (legacy): \(permissionStatus.rawValue)")
            }
            
            // Настраиваем аудиосессию для записи
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("✅ Аудиосессия настроена успешно")
            completion(true)
        } catch {
            print("❌ Ошибка настройки аудиосессии: \(error)")
            completion(false)
        }
    }
    
    private func startAudioRecording() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            print("🎤 Запись аудио начата")
            
        } catch {
            print("❌ Ошибка записи аудио: \(error)")
        }
    }
    
    private func stopAudioRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    private func startSpeechRecognition() {
        guard let audioEngine = audioEngine, let speechRecognizer = speechRecognizer else { 
            print("❌ Аудио движок или распознаватель речи не инициализирован")
            return 
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            return
        }
        
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else { 
                print("❌ Не удалось создать запрос на распознавание")
                return 
            }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            print("🎯 Распознавание речи запущено")
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    let transcript = result.bestTranscription.formattedString
                    print("📝 Транскрипция: \(transcript)")
                }
                
                if error != nil || result?.isFinal == true {
                    self?.audioEngine?.stop()
                    inputNode.removeTap(onBus: 0)
                    self?.recognitionRequest = nil
                    self?.recognitionTask = nil
                    print("🛑 Распознавание речи остановлено")
                }
            }
            
        } catch {
            print("❌ Ошибка распознавания речи: \(error)")
        }
    }
    
    private func stopSpeechRecognition() {
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    private func createTaskFromRecording() {
        let newTask = TaskItem(
            id: UUID(),
            title: "Запись от \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
            description: "Голосовая запись длительностью \(Int(recordingTime)) секунд",
            status: .planned,
            priority: .medium,
            dueDate: nil,
            tags: ["голосовая-запись"],
            isPrivate: false,
            audioURL: nil,
            transcript: nil,
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: nil,
            parentTaskId: nil,
            subtasks: []
        )
        
        tasks.append(newTask)
        print("✅ Создана задача на основе записи")
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
