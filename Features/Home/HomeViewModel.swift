import Foundation
import Combine
import SwiftUI
import AVFoundation
import Speech

// MARK: - Simple TaskManager
@MainActor
class SimpleTaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        var updatedTask = task
        if updatedTask.completedDate == nil {
            // Отмечаем как выполненную
            updatedTask.completedDate = Date()
            updatedTask.status = .completed
        } else {
            // Отмечаем как не выполненную
            updatedTask.completedDate = nil
            updatedTask.status = .planned
        }
        updateTask(updatedTask)
    }
    
    private func saveTasks() {
        // Простое сохранение в UserDefaults
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "savedTasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "savedTasks"),
           let loadedTasks = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = loadedTasks
        }
    }
    
    init() {
        loadTasks()
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var collapsedSections: Set<TaskStatus> = []
    @Published var isRecordingButtonPulsing = false
    
    // TaskManager для управления задачами
    @Published var taskManager = SimpleTaskManager()
    
    // Computed property для задач
    var tasks: [TaskItem] {
        return taskManager.tasks
    }
    
    // MARK: - Recording States
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordingStartTime: Date?
    @Published var waveHeights: [CGFloat] = Array(repeating: 0.3, count: 20)
    
    // MARK: - Transcription and AI Analysis
    @Published var transcript = ""
    @Published var isTranscribing = false
    @Published var aiAnalysisResult: String = ""
    @Published var isAnalyzing = false
    
    // MARK: - UI State
    @Published var showingTaskCreation = false
    @Published var showingAITest = false
    
    // MARK: - Voice Recording (базовая версия)
    
    private var cancellables = Set<AnyCancellable>()
    private var recordingTimer: Timer?
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    // MARK: - AI Service
    private var aiService: any AIServiceProtocol
    
    init() {
        // Используем улучшенный MockAIService с лучшим анализом
        self.aiService = MockAIService()
        print("🤖 Используется улучшенный Mock AI сервис")
        print("💡 Для полного AI функционала нужно добавить LocalAIService.swift в проект Xcode")
        
        print("🚀 HomeViewModel инициализируется")
        setupData()
        startPulsingAnimation()
        setupSpeechRecognition()
        print("✅ HomeViewModel инициализирован")
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
        
        // Сразу устанавливаем состояние записи для UI
        DispatchQueue.main.async {
            self.isRecording = true
            self.recordingStartTime = Date()
            self.recordingTime = 0
            print("🎯 UI обновлен: isRecording = \(self.isRecording)")
        }
        
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
                                    self.startRecordingTimer()
                                    self.setupWaveAnimation()
                                    self.startAudioRecording()
                                    self.startSpeechRecognition()
                                } else {
                                    print("❌ Не удалось настроить аудиосессию")
                                    self.isRecording = false
                                }
                            }
                        } else {
                            print("❌ Разрешение на распознавание речи не получено")
                            self.isRecording = false
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("❌ Разрешение на микрофон не получено")
                    self.isRecording = false
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
                guard let self = self else { return }
                
                if let result = result {
                    let transcript = result.bestTranscription.formattedString
                    print("📝 Транскрипция: \(transcript)")
                    
                    // Сохраняем транскрипцию в реальном времени
                    DispatchQueue.main.async {
                        self.transcript = transcript
                        print("💾 Транскрипция сохранена: \(self.transcript)")
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    self.audioEngine?.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
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
        print("🤖 Начинаем AI анализ голосовой записи...")
        
        // Запускаем AI анализ в асинхронном режиме
        Task {
            await performAIAnalysis()
        }
    }
    
    private func performAIAnalysis() async {
        print("🤖 Выполняем AI анализ голосовой записи...")
        
        do {
            // Анализируем голосовую запись с помощью AI
            let result = try await aiService.analyzeVoiceRecording(transcript, audioURL: nil)
            
            await MainActor.run {
                // Создаем задачи на основе AI анализа
                for extractedTask in result.tasks {
                    let newTask = TaskItem(
                        title: extractedTask.title,
                        description: extractedTask.description ?? "Задача создана AI на основе голосовой записи",
                        status: .planned,
                        priority: extractedTask.priority,
                        dueDate: extractedTask.dueDate,
                        tags: extractedTask.tags + ["ai-создана", "голосовая-запись"],
                        isPrivate: false,
                        audioURL: nil,
                        transcript: transcript,
                        createdAt: Date(),
                        updatedAt: Date(),
                        completedDate: nil,
                        parentTaskId: nil,
                        subtasks: []
                    )
                    taskManager.addTask(newTask)
                    print("✅ Создана AI задача: \(extractedTask.title)")
                }
                
                // Если AI не смог извлечь задачи, создаем общую запись
                                        if result.tasks.isEmpty {
                    let generalTask = TaskItem(
                        title: "Запись от \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
                        description: transcript.isEmpty ? "Голосовая запись длительностью \(Int(recordingTime)) секунд" : transcript,
                        status: .planned,
                        priority: .medium,
                        dueDate: nil,
                        tags: ["голосовая-запись", "ai-анализ"],
                        isPrivate: false,
                        audioURL: nil,
                        transcript: transcript.isEmpty ? nil : transcript,
                        createdAt: Date(),
                        updatedAt: Date(),
                        completedDate: nil,
                        parentTaskId: nil,
                        subtasks: []
                    )
                    taskManager.addTask(generalTask)
                    print("✅ Создана общая задача на основе записи")
                }
                
                // Генерируем AI анализ для отображения
                aiAnalysisResult = result.summary
                
                // Очищаем транскрипцию для следующей записи
                transcript = ""
                                        print("🎯 AI анализ завершен. Создано задач: \(result.tasks.count)")
            }
            
        } catch {
            print("❌ Ошибка AI анализа: \(error)")
            
            // В случае ошибки создаем простую задачу
            await MainActor.run {
                let fallbackTask = TaskItem(
                    title: "Запись от \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
                    description: transcript.isEmpty ? "Голосовая запись длительностью \(Int(recordingTime)) секунд" : transcript,
                    status: .planned,
                    priority: .medium,
                    dueDate: nil,
                    tags: ["голосовая-запись", "ошибка-ai"],
                    isPrivate: false,
                    audioURL: nil,
                    transcript: transcript.isEmpty ? nil : transcript,
                    createdAt: Date(),
                    updatedAt: Date(),
                    completedDate: nil,
                    parentTaskId: nil,
                    subtasks: []
                )
                taskManager.addTask(fallbackTask)
                transcript = ""
                aiAnalysisResult = "AI анализ не удался, но запись сохранена"
            }
        }
    }
    
    // MARK: - AI Testing
    
    func testAIService() {
        print("🧪 Тестирование AI сервиса...")
        print("🤖 Текущий сервис: \(type(of: aiService))")
        
        // Простой тест Mock сервиса
        Task {
            do {
                let result = try await aiService.analyzeVoiceRecording("Нужно купить хлеб завтра", audioURL: nil)
                print("📊 Результат теста: \(result.tasks.count) задач найдено")
            } catch {
                print("❌ Ошибка теста: \(error)")
            }
        }
    }
    
    // MARK: - AI Analysis Methods
    
    private func generateAIAnalysis(transcript: String, tasksCount: Int) -> String {
        var analysis = "🎯 **AI анализ голосовой записи**\n\n"
        
        if tasksCount > 0 {
            analysis += "✅ **Извлечено задач:** \(tasksCount)\n"
            analysis += "📝 **Транскрипция:** \(transcript.prefix(100))...\n\n"
            
            if tasksCount == 1 {
                analysis += "Отлично! AI смог выделить одну задачу из вашей записи."
            } else if tasksCount <= 3 {
                analysis += "Хорошо! AI выделил несколько задач для планирования."
            } else {
                analysis += "Отлично! AI обработал сложную запись и выделил множество задач."
            }
        } else {
            analysis += "📝 **Транскрипция:** \(transcript.prefix(100))...\n\n"
            analysis += "AI не смог выделить конкретные задачи, но сохранил вашу запись для дальнейшего анализа."
        }
        
        return analysis
    }
    
    private func extractTasksFromTranscript(_ transcript: String) -> [ExtractedTask] {
        var tasks: [ExtractedTask] = []
        
        // Простой AI анализ для извлечения задач
        let sentences = transcript.components(separatedBy: [".", "!", "?"])
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 10 && isTaskSentence(trimmed) {
                let task = ExtractedTask(
                    title: generateTaskTitle(from: trimmed),
                    description: trimmed,
                    priority: determinePriority(from: trimmed),
                    dueDate: extractDueDate(from: trimmed),
                    tags: extractTags(trimmed),
                    confidence: 0.8
                )
                tasks.append(task)
            }
        }
        
        return tasks
    }
    
    private func isTaskSentence(_ sentence: String) -> Bool {
        let taskKeywords = [
            "нужно", "должен", "планирую", "хочу", "сделать", "завершить", "подготовить", 
            "встретиться", "позвонить", "купить", "записаться", "изучить", "прочитать",
            "написать", "отправить", "проверить", "обновить", "создать", "разработать",
            "организовать", "планирую", "собираюсь", "надо", "следует", "важно"
        ]
        
        let lowercased = sentence.lowercased()
        return taskKeywords.contains { lowercased.contains($0) } || 
               lowercased.contains("завтра") || 
               lowercased.contains("сегодня") ||
               lowercased.contains("на этой неделе")
    }
    
    private func generateTaskTitle(from sentence: String) -> String {
        // Извлекаем ключевые слова для названия задачи
        let words = sentence.components(separatedBy: " ")
        let stopWords = [
            "нужно", "должен", "планирую", "хочу", "сделать", "завершить", "подготовить",
            "встретиться", "позвонить", "купить", "записаться", "изучить", "прочитать",
            "написать", "отправить", "проверить", "обновить", "создать", "разработать",
            "организовать", "планирую", "собираюсь", "надо", "следует", "важно", "это",
            "было", "будет", "есть", "стал", "стала", "стали", "стало"
        ]
        
        let keyWords = words.filter { word in
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return cleanWord.count > 2 && !stopWords.contains(cleanWord)
        }
        
        let title = keyWords.prefix(5).joined(separator: " ")
        return title.isEmpty ? "Задача из голосовой записи" : title.capitalized
    }
    
    private func determinePriority(from sentence: String) -> TaskPriority {
        let highPriorityKeywords = ["срочно", "важно", "критично", "немедленно"]
        let lowPriorityKeywords = ["потом", "когда-нибудь", "не срочно"]
        
        if highPriorityKeywords.contains(where: { sentence.lowercased().contains($0) }) {
            return .high
        } else if lowPriorityKeywords.contains(where: { sentence.lowercased().contains($0) }) {
            return .low
        }
        return .medium
    }
    
    private func extractDueDate(from sentence: String) -> Date? {
        let today = Date()
        let calendar = Calendar.current
        
        if sentence.lowercased().contains("сегодня") {
            return today
        } else if sentence.lowercased().contains("завтра") {
            return calendar.date(byAdding: .day, value: 1, to: today)
        } else if sentence.lowercased().contains("на этой неделе") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: today)
        }
        
        return nil
    }
    
    private func extractTags(_ text: String) -> [String] {
        var tags: [String] = []
        let lowercased = text.lowercased()
        
        // Извлекаем хештеги
        let hashtagPattern = "#\\w+"
        let regex = try? NSRegularExpression(pattern: hashtagPattern)
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, range: range) ?? []
        
        for match in matches {
            if let range = Range(match.range, in: text) {
                let tag = String(text[range])
                tags.append(tag)
            }
        }
        
        // Добавляем автоматические теги на основе контекста
        let contextTags: [(keywords: [String], tag: String)] = [
            (["встреча", "встретиться", "собрание", "конференция"], "встреча"),
            (["звонок", "позвонить", "телефон"], "звонок"),
            (["проект", "разработка", "код", "программирование"], "проект"),
            (["покупки", "купить", "магазин", "заказ"], "покупки"),
            (["здоровье", "врач", "больница", "аптека"], "здоровье"),
            (["спорт", "тренировка", "фитнес", "зал"], "спорт"),
            (["обучение", "изучить", "курс", "книга"], "обучение"),
            (["работа", "офис", "клиент", "заказчик"], "работа"),
            (["быт", "уборка", "стирка", "готовка"], "быт"),
            (["финансы", "деньги", "счет", "платеж"], "финансы")
        ]
        
        for contextTag in contextTags {
            if contextTag.keywords.contains(where: { lowercased.contains($0) }) {
                tags.append(contextTag.tag)
            }
        }
        
        // Добавляем тег по приоритету
        if lowercased.contains("срочно") || lowercased.contains("важно") || lowercased.contains("критично") {
            tags.append("срочно")
        }
        
        return Array(Set(tags)) // Убираем дубликаты
    }
    
    private func generateSummary(_ transcript: String) -> String {
        let sentences = transcript.components(separatedBy: [".", "!", "?"])
        let keySentences = sentences.prefix(3).joined(separator: ". ")
        return keySentences + "."
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
        // Простой расчет streak
        var streak = 0
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 0... {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let tasksForDay = tasks.filter { task in
                guard let taskDate = task.dueDate else { return false }
                return calendar.isDate(taskDate, inSameDayAs: date)
            }
            
            if tasksForDay.isEmpty {
                break
            }
            
            let completedCount = tasksForDay.filter { $0.completedDate != nil }.count
            if completedCount > 0 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
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
        taskManager.toggleTaskCompletion(task)
    }
    
    func snoozeTask(_ task: TaskItem, until date: Date) {
        var updatedTask = task
        updatedTask.dueDate = date
        taskManager.updateTask(updatedTask)
    }
    
    func deleteTask(_ task: TaskItem) {
        taskManager.deleteTask(task)
    }
    
    // MARK: - Private Methods
    
    private func setupData() {
        // Загружаем задачи из TaskManager
        if taskManager.tasks.isEmpty {
            loadSampleData()
        }
    }
    
    private func startPulsingAnimation() {
        // Отключаем пульсацию кнопки записи
        isRecordingButtonPulsing = false
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
        
        for task in sampleTasks {
            taskManager.addTask(task)
        }
    }
    
    // MARK: - Task Status Ordering
    
    var orderedTaskStatuses: [TaskStatus] {
        // Правильный порядок блоков задач
        return [
            .important,      // Важное - вверху
            .planned,        // В планах
            .stuck,          // Застряло
            .waiting,        // Ожидает ответа
            .delegated,      // Делегировано
            .paused,         // На паузе
            .recurring,      // Повторяющееся
            .idea,           // Идеи на потом
            .completed       // Свершилось - внизу
        ]
    }
}
