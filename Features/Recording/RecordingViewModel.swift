import SwiftUI
import AVFoundation
import Speech
import Combine

@MainActor
class RecordingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var isProcessing = false
    @Published var hasResults = false
    @Published var selectedTemplate: VoiceTemplate?
    @Published var liveTranscription = ""
    @Published var recordingTime = "00:00"
    @Published var buttonScale: CGFloat = 1.0
    @Published var waveHeights: [CGFloat] = Array(repeating: 20, count: 20)
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var tasksByStatus: [TaskStatus: [TaskItem]] = [:]
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var waveTimer: Timer?
    
    private let audioService = AudioRecordingService()
    private let aiService = AIAnalysisService()
    
    init() {
        setupSpeechRecognition()
        setupWaveAnimation()
    }
    
    // MARK: - Public Methods
    
    func requestPermissions() {
        Task {
            await requestMicrophonePermission()
            await requestSpeechRecognitionPermission()
        }
    }
    
    func selectTemplate(_ template: VoiceTemplate) {
        selectedTemplate = template
    }
    
    func startRecording() {
        Task {
            await startAudioRecording()
        }
    }
    
    func pauseRecording() {
        if isPaused {
            resumeRecording()
        } else {
            pauseAudioRecording()
        }
    }
    
    func stopRecording() {
        Task {
            await stopAudioRecording()
        }
    }
    
    func cancelRecording() {
        cancelAudioRecording()
    }
    
    func editTask(_ task: TaskItem) {
        // TODO: Implement task editing
        print("Edit task: \(task.title)")
    }
    
    func editAllTasks() {
        // TODO: Implement bulk editing
        print("Edit all tasks")
    }
    
    func saveAllTasks() {
        // TODO: Save tasks to TaskManager
        print("Saving all tasks")
    }
    
    func saveAsTemplate() {
        // TODO: Save current recording as template
        print("Saving as template")
    }
    
    // MARK: - Private Methods
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        speechRecognizer?.delegate = nil
    }
    
    private func setupWaveAnimation() {
        waveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            
            for i in 0..<self.waveHeights.count {
                self.waveHeights[i] = CGFloat.random(in: 10...60)
            }
        }
    }
    
    private func requestMicrophonePermission() async {
        let status = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        if !status {
            await MainActor.run {
                showError = true
                errorMessage = "Необходим доступ к микрофону для записи голоса"
            }
        }
    }
    
    private func requestSpeechRecognitionPermission() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        if status != .authorized {
            await MainActor.run {
                showError = true
                errorMessage = "Необходим доступ к распознаванию речи для транскрипции"
            }
        }
    }
    
    private func startAudioRecording() async {
        do {
            try await audioService.startRecording()
            
            await MainActor.run {
                isRecording = true
                isPaused = false
                hasResults = false
                liveTranscription = ""
                recordingStartTime = Date()
                buttonScale = 1.1
                startRecordingTimer()
                startLiveTranscription()
            }
        } catch {
            await MainActor.run {
                showError = true
                errorMessage = "Ошибка начала записи: \(error.localizedDescription)"
            }
        }
    }
    
    private func pauseAudioRecording() {
        audioService.pauseRecording()
        isPaused = true
        recordingTimer?.invalidate()
    }
    
    private func resumeRecording() {
        audioService.resumeRecording()
        isPaused = false
        startRecordingTimer()
    }
    
    private func stopAudioRecording() async {
        guard let audioURL = audioService.stopRecording() else {
            await MainActor.run {
                showError = true
                errorMessage = "Ошибка остановки записи"
            }
            return
        }
        
        await MainActor.run {
            isRecording = false
            isPaused = false
            buttonScale = 1.0
            recordingTimer?.invalidate()
            stopLiveTranscription()
        }
        
        // Start AI analysis
        await analyzeRecording(audioURL: audioURL)
    }
    
    private func cancelAudioRecording() {
        audioService.cancelRecording()
        
        isRecording = false
        isPaused = false
        buttonScale = 1.0
        recordingTimer?.invalidate()
        stopLiveTranscription()
        liveTranscription = ""
        recordingTime = "00:00"
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            
            let duration = Date().timeIntervalSince(startTime)
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            self.recordingTime = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func startLiveTranscription() {
        // Start live speech recognition
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    Task { @MainActor in
                        self.liveTranscription = transcribedText
                    }
                }
                
                if error != nil {
                    self.stopLiveTranscription()
                }
            }
            
        } catch {
            print("Error starting live transcription: \(error)")
        }
    }
    
    private func stopLiveTranscription() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    private func analyzeRecording(audioURL: URL) async {
        await MainActor.run {
            isProcessing = true
        }
        
        // Simulate AI analysis delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Get transcription from the final result
        let finalTranscription = liveTranscription.isEmpty ? "Сегодня сделал уборку в доме, купил продукты. Завтра нужно позвонить маме и записаться к врачу. Важно не забыть оплатить счета." : liveTranscription
        
        // Analyze with AI service
        let aiResult = await aiService.analyzeVoiceRecording(
            transcript: finalTranscription,
            template: selectedTemplate
        )
        
        await MainActor.run {
            isProcessing = false
            hasResults = true
            
            // Organize tasks by status
            tasksByStatus = Dictionary(grouping: aiResult.tasks, by: { $0.status })
        }
    }
}

// MARK: - Voice Template
// Используем VoiceTemplate из Core/Models/VoiceRecord.swift
