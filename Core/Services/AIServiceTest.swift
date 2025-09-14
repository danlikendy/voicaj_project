import Foundation

// MARK: - AI Service Test
class AIServiceTest {
    
    static func testAIService() async {
        print("🧪 Начинаем тестирование AI сервиса...")
        
        let aiService = AIServiceFactory.createAIService()
        
        // Тест 1: Проверка типа сервиса
        if aiService is MockAIService {
            print("⚠️ Используется Mock AI сервис - API ключ не настроен")
            print("💡 Для настройки смотрите AI_SETUP_INSTRUCTIONS.md")
        } else {
            print("✅ Используется настоящий GPT-4o сервис")
        }
        
        // Тест 2: Анализ голосовой записи
        let testTranscript = "Завтра нужно купить продукты в магазине, это важно. Также планирую позвонить маме и записаться к врачу на следующей неделе."
        
        do {
            print("🧪 Тестируем анализ голосовой записи...")
            let result = try await aiService.analyzeVoiceRecording(testTranscript, audioURL: nil)
            
            print("📊 Результат анализа:")
            print("   - Найдено задач: \(result.tasks.count)")
            print("   - Уверенность: \(result.confidence)")
            print("   - Сводка: \(result.summary)")
            
            for (index, task) in result.tasks.enumerated() {
                print("   📋 Задача \(index + 1):")
                print("      - Название: \(task.title)")
                print("      - Описание: \(task.description ?? "Нет описания")")
                print("      - Приоритет: \(task.priority)")
                print("      - Теги: \(task.tags.joined(separator: ", "))")
                if let dueDate = task.dueDate {
                    print("      - Срок: \(dueDate)")
                }
            }
            
        } catch {
            print("❌ Ошибка при анализе: \(error)")
        }
        
        // Тест 3: Генерация ответа в чате
        do {
            print("🧪 Тестируем генерацию ответа в чате...")
            let response = try await aiService.generateResponse(for: "Привет! Как дела?", context: [])
            print("💬 Ответ AI: \(response)")
        } catch {
            print("❌ Ошибка при генерации ответа: \(error)")
        }
        
        print("🏁 Тестирование завершено")
    }
    
    static func testMockService() async {
        print("🧪 Тестируем Mock AI сервис...")
        
        let mockService = MockAIService()
        
        // Тест анализа
        do {
            let result = try await mockService.analyzeVoiceRecording("Нужно купить хлеб завтра", audioURL: nil)
            print("📊 Mock анализ: \(result.tasks.count) задач найдено")
        } catch {
            print("❌ Ошибка Mock сервиса: \(error)")
        }
        
        // Тест чата
        do {
            let response = try await mockService.generateResponse(for: "Привет", context: [])
            print("💬 Mock ответ: \(response)")
        } catch {
            print("❌ Ошибка Mock чата: \(error)")
        }
    }
}


