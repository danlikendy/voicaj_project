import Foundation

// MARK: - AI Configuration
struct AIConfig {
    // OpenAI API Key - замените на свой
    // Для получения ключа: https://platform.openai.com/api-keys
    // ВАЖНО: Никогда не коммитьте реальные API ключи в репозиторий!
    static let openAIKey = "your-openai-api-key-here"
    
    // Альтернативные API ключи
    static let claudeKey = "your-claude-api-key-here"
    static let mistralKey = "your-mistral-api-key-here"
    
    // Настройки моделей
    static let defaultModel = "gpt-4o-mini"
    static let advancedModel = "gpt-4o"
    
    // Лимиты токенов
    static let maxTokens = 1000
    static let maxTokensAdvanced = 1500
    
    // Температура (креативность)
    static let defaultTemperature = 0.7
    static let structuredTemperature = 0.3
}

// MARK: - Environment Variables
extension AIConfig {
    static var openAIKeyFromEnv: String {
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? openAIKey
    }
    
    static var claudeKeyFromEnv: String {
        return ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? claudeKey
    }
    
    static var mistralKeyFromEnv: String {
        return ProcessInfo.processInfo.environment["MISTRAL_API_KEY"] ?? mistralKey
    }
}
