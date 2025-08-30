import SwiftUI

@main
struct VoiceActionJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Инициализация приложения
                    print("🚀 Voicaj запущен!")
                }
        }
    }
}
