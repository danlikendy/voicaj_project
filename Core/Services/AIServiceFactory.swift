import Foundation

// MARK: - AI Service Factory
class AIServiceFactory {
    enum AIServiceType {
        case localOllama
        case openAI
        case mock
    }
    
    static func createAIService(type: AIServiceType = .localOllama) -> any AIServiceProtocol {
        switch type {
        case .localOllama:
            print("🤖 Используем локальную модель Ollama (Qwen2.5)")
            return LocalAIService()
            
        case .openAI:
            let apiKey = AIConfig.openAIKeyFromEnv
            
            // Проверяем, что API ключ настроен
            if apiKey.isEmpty || apiKey == "your-openai-api-key-here" || apiKey == "sk-proj-your-key-here" {
                print("⚠️ OpenAI API ключ не настроен, переключаемся на локальную модель")
                return LocalAIService()
            }
            
            print("✅ Используем OpenAI GPT-4o сервис")
            return AIService(apiKey: apiKey)
            
        case .mock:
            print("🤖 Используем Mock AI сервис")
            return MockAIService()
        }
    }
    
    static func createAIService() -> any AIServiceProtocol {
        // По умолчанию используем локальную модель
        return createAIService(type: .localOllama)
    }
    
    static func createAIServiceWithKey(_ apiKey: String) -> any AIServiceProtocol {
        if apiKey.isEmpty {
            print("⚠️ Пустой API ключ, используем Mock AI сервис")
            return MockAIService()
        }
        
        print("✅ Используем настоящий OpenAI GPT-4o сервис с предоставленным ключом")
        return AIService(apiKey: apiKey)
    }
}


