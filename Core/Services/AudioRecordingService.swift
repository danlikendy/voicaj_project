import Foundation
import AVFoundation
import Combine
import Speech

class AudioRecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var error: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var recordingTimer: Timer?
    private var audioLevelTimer: Timer?
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        setupSpeechRecognition()
    }
    
    // MARK: - Setup
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    break
                case .denied, .restricted, .notDetermined:
                    self?.error = "Нет доступа к распознаванию речи"
                @unknown default:
                    self?.error = "Неизвестная ошибка доступа к распознаванию речи"
                }
            }
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        do {
            try setupAudioSession()
            try startAudioRecording()
            try startSpeechRecognition()
            
            isRecording = true
            isPaused = false
            recordingDuration = 0
            
            startTimers()
            
        } catch {
            self.error = "Ошибка начала записи: \(error.localizedDescription)"
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        stopTimers()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        isPaused = false
        startTimers()
    }
    
    func stopRecording() -> URL? {
        stopTimers()
        
        audioRecorder?.stop()
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        
        isRecording = false
        isPaused = false
        
        return audioRecorder?.url
    }
    
    func cancelRecording() {
        stopTimers()
        
        audioRecorder?.stop()
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        
        // Удаляем записанный файл
        if let url = audioRecorder?.url {
            try? FileManager.default.removeItem(at: url)
        }
        
        isRecording = false
        isPaused = false
        recordingDuration = 0
        audioLevel = 0.0
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
    }
    
    private func startAudioRecording() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
    }
    
    private func startSpeechRecognition() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw AudioRecordingError.speechRecognitionNotAvailable
        }
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = "Ошибка распознавания: \(error.localizedDescription)"
                }
                return
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    // Здесь можно обновить транскрипт в реальном времени
                    // self?.transcript = result.bestTranscription.formattedString
                }
            }
        }
    }
    
    private func startTimers() {
        // Таймер для длительности записи
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
        
        // Таймер для уровня аудио
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }
    
    private func stopTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    private func updateAudioLevel() {
        audioRecorder?.updateMeters()
        audioLevel = audioRecorder?.averagePower(forChannel: 0) ?? 0.0
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            error = "Запись завершилась с ошибкой"
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            self.error = "Ошибка кодирования: \(error.localizedDescription)"
        }
    }
}

// MARK: - Errors

enum AudioRecordingError: Error, LocalizedError {
    case speechRecognitionNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .speechRecognitionNotAvailable:
            return "Распознавание речи недоступно"
        }
    }
}
