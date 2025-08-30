import Foundation
import Combine

@MainActor
class VoiceRecordManager: ObservableObject {
    @Published var voiceRecords: [VoiceRecord] = []
    
    private let userDefaults = UserDefaults.standard
    private let voiceRecordsKey = "savedVoiceRecords"
    
    init() {
        loadVoiceRecords()
    }
    
    // MARK: - CRUD Operations
    
    func addVoiceRecord(_ record: VoiceRecord) {
        voiceRecords.append(record)
        saveVoiceRecords()
    }
    
    func updateVoiceRecord(_ record: VoiceRecord) {
        if let index = voiceRecords.firstIndex(where: { $0.id == record.id }) {
            voiceRecords[index] = record
            saveVoiceRecords()
        }
    }
    
    func deleteVoiceRecord(_ record: VoiceRecord) {
        voiceRecords.removeAll { $0.id == record.id }
        saveVoiceRecords()
    }
    
    // MARK: - Query Methods
    
    func getVoiceRecords(for date: Date? = nil) -> [VoiceRecord] {
        if let date = date {
            let calendar = Calendar.current
            return voiceRecords.filter { record in
                calendar.isDate(record.createdAt, inSameDayAs: date)
            }
        }
        return voiceRecords
    }
    
    func getRecentVoiceRecords(limit: Int = 10) -> [VoiceRecord] {
        return Array(voiceRecords.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    // MARK: - Persistence
    
    private func saveVoiceRecords() {
        if let data = try? JSONEncoder().encode(voiceRecords) {
            userDefaults.set(data, forKey: voiceRecordsKey)
        }
    }
    
    private func loadVoiceRecords() {
        if let data = userDefaults.data(forKey: voiceRecordsKey),
           let loadedRecords = try? JSONDecoder().decode([VoiceRecord].self, from: data) {
            voiceRecords = loadedRecords
        }
    }
}
