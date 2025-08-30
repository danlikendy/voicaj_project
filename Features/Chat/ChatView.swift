import SwiftUI

struct ChatView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        // Временно используем простую инициализацию без AI
        self._viewModel = StateObject(wrappedValue: ChatViewModel(homeViewModel: homeViewModel))
    }
    
    var body: some View {
        
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Space for input
                    }
                    .onChange(of: viewModel.messages.count) { oldCount, newCount in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.parchment)
                    
                    HStack(spacing: 16) {
                        // Message Input
                        HStack(spacing: 12) {
                            TextField("Напишите сообщение...", text: $messageText, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($isTextFieldFocused)
                                .lineLimit(1...4)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.porcelain)
                                .cornerRadius(20)
                                .onTapGesture {
                                    isTextFieldFocused = true
                                }
                                .onSubmit {
                                    print("⌨️ Enter нажат в текстовом поле")
                                    if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        sendMessage()
                                    }
                                }
                            
                            // Send Button
                            Button(action: {
                                print("🔘 Кнопка отправки нажата")
                                sendMessage()
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .honeyGold))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .tobacco : .honeyGold)
                                }
                            }
                            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                            .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.porcelain)
                }
            }
            .navigationTitle("AI Ассистент")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Убираем корзину - она не нужна
            }
        }
        .background(Color.porcelain)
        .onAppear {
            viewModel.loadInitialMessage()
        }
        .onTapGesture {
            // Скрываем клавиатуру при тапе по экрану
            isTextFieldFocused = false
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("📤 sendMessage() вызвана")
        print("📤 Исходный текст: '\(messageText)'")
        print("📤 Обрезанный текст: '\(trimmedText)'")
        print("📤 Длина текста: \(trimmedText.count)")
        
        guard !trimmedText.isEmpty else { 
            print("❌ Текст пустой, отправка отменена")
            return 
        }
        
        print("✅ Отправляем сообщение: '\(trimmedText)'")
        print("✅ Вызываем viewModel.sendMessage")
        
        viewModel.sendMessage(trimmedText)
        
        print("✅ viewModel.sendMessage выполнен")
        messageText = ""
        print("✅ Поле очищено")
        
        // Простое снятие фокуса
        isTextFieldFocused = false
        print("✅ Фокус снят")
        
        print("✅ Сообщение отправлено, поле очищено")
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.honeyGold)
                        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.tobacco)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16))
                            .foregroundColor(.honeyGold)
                        
                        Text("AI Ассистент")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.tobacco)
                    }
                    
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.espresso)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.porcelain)
                        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.tobacco)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType
    
    enum MessageType: String, Codable {
        case text
        case taskCreation
        case taskSearch
        case aiRecommendation
    }
    
    init(content: String, isFromUser: Bool, messageType: MessageType = .text) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.messageType = messageType
    }
}

// MARK: - Chat ViewModel
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @ObservedObject var homeViewModel: HomeViewModel
    
    private let aiService: any AIServiceProtocol
    @Published var isLoading = false
    
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        
        // Восстанавливаем Mock AI сервис для тестирования
        self.aiService = MockAIService()
        print("🤖 ChatView: Используется Mock AI сервис для тестирования")
    }
    
    func loadInitialMessage() {
        if messages.isEmpty {
            let welcomeMessage = ChatMessage(
                content: "Привет! 👋 Я ваш AI ассистент. Готов помочь с задачами и планированием. Что нужно?",
                isFromUser: false,
                messageType: .aiRecommendation
            )
            messages.append(welcomeMessage)
        }
    }
    
    func sendMessage(_ text: String) {
        print("🤖 ChatViewModel.sendMessage вызван с текстом: '\(text)'")
        print("🤖 Длина текста: \(text.count)")
        
        // Добавляем сообщение пользователя
        let userMessage = ChatMessage(content: text, isFromUser: true)
        messages.append(userMessage)
        
        print("✅ Сообщение пользователя добавлено, всего сообщений: \(messages.count)")
        
        // Показываем индикатор загрузки
        isLoading = true
        print("✅ Индикатор загрузки показан")
        
        // Генерируем настоящий AI ответ
        print("🤖 Запускаем Task для generateAIResponse")
        Task {
            print("🤖 Task запущен")
            await generateAIResponse(for: text)
            print("🤖 Task завершен")
        }
        print("🤖 Task отправлен в очередь")
    }
    
    private func generateAIResponse(for userMessage: String) async {
        print("🤖 Генерируем AI ответ для: \(userMessage)")
        
        do {
            // Получаем контекст предыдущих сообщений
            let context = messages.suffix(5).map { $0.content }
            
            // Проверяем, нужно ли создать задачу
            if shouldCreateTask(from: userMessage) {
                print("🤖 Создаем задачу из сообщения")
                let result = try await aiService.createTaskFromMessage(userMessage, context: context)
                
                await MainActor.run {
                    if result.success, let task = result.task {
                        // Создаем задачу
                        self.createTaskFromAIResult(task)
                        let message = ChatMessage(content: result.message, isFromUser: false)
                        self.messages.append(message)
                        print("✅ Задача создана из чата")
                    } else {
                        // Обычный ответ
                        let message = ChatMessage(content: result.message, isFromUser: false)
                        self.messages.append(message)
                        print("✅ Обычный ответ AI")
                    }
                    self.isLoading = false
                }
            } else {
                // Обычный AI ответ
                print("🤖 Генерируем обычный AI ответ")
                let response = try await aiService.generateResponse(for: userMessage, context: context)
                
                await MainActor.run {
                    let message = ChatMessage(content: response, isFromUser: false)
                    self.messages.append(message)
                    self.isLoading = false
                    print("✅ AI ответ добавлен: \(response.prefix(50))...")
                }
            }
            
            print("✅ AI ответ добавлен")
        } catch {
            print("❌ Ошибка AI: \(error)")
            
            // В случае ошибки даем fallback ответ
            await MainActor.run {
                let fallbackMessage = ChatMessage(
                    content: "Извините, произошла ошибка при обработке вашего сообщения. Попробуйте еще раз или используйте голосовую запись для создания задач.",
                    isFromUser: false
                )
                self.messages.append(fallbackMessage)
                self.isLoading = false
            }
        }
    }
    
    private func generateContextualResponse(to message: String) -> String {
        let lowercased = message.lowercased()
        
        // Простые ответы на основе ключевых слов
        if lowercased.contains("задача") || lowercased.contains("создать") || lowercased.contains("добавить") {
            return "Я помогу создать задачу! Для этого используйте голосовую запись или напишите подробно, что нужно сделать. Например: 'Создать задачу: купить продукты завтра'"
        }
        
        if lowercased.contains("привет") || lowercased.contains("здравствуй") {
            return "Привет! Чем могу помочь? Могу создать задачи, ответить на вопросы или помочь с планированием."
        }
        
        if lowercased.contains("спасибо") || lowercased.contains("благодарю") {
            return "Рад помочь! Если нужна еще помощь, просто пишите."
        }
        
        if lowercased.contains("помощь") || lowercased.contains("что умеешь") {
            return "Я умею:\n• Создавать задачи из текста и голосовых записей\n• Отвечать на вопросы\n• Помогать с планированием\n• Анализировать голосовые сообщения\n\nПросто скажите, что вам нужно!"
        }
        
        // Если сообщение похоже на задачу, предлагаем создать её
        if isTaskLikeMessage(message) {
            return "Это похоже на задачу! Я могу создать её для вас. Просто подтвердите или уточните детали."
        }
        
        // Общий ответ
        return "Понял! Если у вас есть конкретная задача или вопрос, я готов помочь. Можете также использовать голосовую запись для создания задач."
    }
    
    private func isTaskLikeMessage(_ message: String) -> Bool {
        let taskKeywords = [
            "нужно", "должен", "планирую", "хочу", "сделать", "завершить", "подготовить",
            "встретиться", "позвонить", "купить", "записаться", "изучить", "прочитать",
            "написать", "отправить", "проверить", "обновить", "создать", "разработать"
        ]
        
        let lowercased = message.lowercased()
        return taskKeywords.contains { lowercased.contains($0) } ||
               lowercased.contains("завтра") ||
               lowercased.contains("сегодня") ||
               lowercased.contains("на этой неделе")
    }
    
    // AI функциональность временно отключена
    /*
    private func generateAIResponse(for userMessage: String) async {
        print("🤖 Генерируем AI ответ для: \(userMessage)")
        
        do {
            // Получаем контекст предыдущих сообщений
            let context = messages.suffix(5).map { $0.content }
            
            // Проверяем, нужно ли создать задачу
            if shouldCreateTask(from: userMessage) {
                let result = try await aiService.createTaskFromMessage(userMessage, context: context)
                
                await MainActor.run {
                    if result.success, let task = result.task {
                        // Создаем задачу
                        self.createTaskFromAIResult(task)
                        let message = ChatMessage(content: result.message, isFromUser: false)
                        self.messages.append(message)
                    } else {
                        // Обычный ответ
                        let message = ChatMessage(content: result.message, isFromUser: false)
                        self.messages.append(message)
                    }
                    self.isLoading = false
                }
            } else {
                // Обычный AI ответ
                let response = try await aiService.generateResponse(for: userMessage, context: context)
                
                await MainActor.run {
                    let message = ChatMessage(content: response, isFromUser: false)
                    self.messages.append(message)
                    self.isLoading = false
                }
            }
            
            print("✅ AI ответ добавлен")
        } catch {
            print("❌ Ошибка AI: \(error)")
            
            await MainActor.run {
                let errorMessage = ChatMessage(
                    content: "Извините, произошла ошибка при обработке вашего сообщения. Попробуйте еще раз.",
                    isFromUser: false
                )
                self.messages.append(errorMessage)
                self.isLoading = false
            }
        }
    }
    
    private func shouldCreateTask(from message: String) -> Bool {
        let taskKeywords = [
            "создать задачу", "добавить задачу", "новая задача", "запланировать",
            "нужно сделать", "должен", "планирую", "хочу"
        ]
        
        let lowercased = message.lowercased()
        return taskKeywords.contains { lowercased.contains($0) }
    }
    
    private func createTaskFromAIResult(_ extractedTask: ExtractedTask) {
        let task = TaskItem(
            title: extractedTask.title,
            description: extractedTask.description ?? "Задача создана из чата",
            priority: extractedTask.priority,
            status: .planned,
            dueDate: extractedTask.dueDate,
            tags: extractedTask.tags + ["создано-из-чата"],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        homeViewModel.taskManager.addTask(task)
        print("✅ Задача создана из чата: \(task.title)")
    }
    */
    
    // MARK: - Task Creation
    private func createTaskFromMessage(_ text: String) -> String {
        // Умный парсинг для создания задачи
        let lowercased = text.lowercased()
        var taskTitle = ""
        var priority: TaskPriority = .medium
        var status: TaskStatus = .planned
        var dueDate: Date? = nil
        var tags: [String] = []
        
        // Извлекаем название задачи (между кавычками или после ключевых слов)
        if let quoteStart = text.range(of: "\"")?.lowerBound,
           let quoteEnd = text.range(of: "\"", range: quoteStart..<text.endIndex)?.upperBound {
            taskTitle = String(text[quoteStart..<quoteEnd])
        } else {
            // Ищем ключевые слова для извлечения названия
            let taskKeywords = ["задача", "создать", "добавить", "новая", "нужно", "хочу", "планирую", "сделать"]
            for keyword in taskKeywords {
                if let keywordIndex = lowercased.range(of: keyword)?.upperBound {
                    let remainingText = String(text[keywordIndex...]).trimmingCharacters(in: .whitespaces)
                    if remainingText.count > 3 {
                        taskTitle = remainingText
                        break
                    }
                }
            }
        }
        
        // Определяем приоритет по ключевым словам
        if lowercased.contains("срочно") || lowercased.contains("важно") || lowercased.contains("критично") || lowercased.contains("немедленно") {
            priority = .high
            status = .important
            tags.append("срочно")
        } else if lowercased.contains("низкий") || lowercased.contains("потом") || lowercased.contains("когда-нибудь") {
            priority = .low
            tags.append("низкий-приоритет")
        }
        
        // Определяем срок выполнения
        let calendar = Calendar.current
        let today = Date()
        
        if lowercased.contains("сегодня") {
            dueDate = today
            tags.append("сегодня")
        } else if lowercased.contains("завтра") {
            dueDate = calendar.date(byAdding: .day, value: 1, to: today)
            tags.append("завтра")
        } else if lowercased.contains("на этой неделе") || lowercased.contains("на неделе") {
            dueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: today)
            tags.append("на-неделе")
        }
        
        // Добавляем контекстные теги
        if lowercased.contains("встреча") || lowercased.contains("собрание") {
            tags.append("встреча")
        }
        if lowercased.contains("звонок") || lowercased.contains("позвонить") {
            tags.append("звонок")
        }
        if lowercased.contains("проект") || lowercased.contains("разработка") {
            tags.append("проект")
        }
        if lowercased.contains("покупки") || lowercased.contains("купить") {
            tags.append("покупки")
        }
        
        // Если название не найдено, просим уточнить
        if taskTitle.isEmpty || taskTitle.count < 3 {
            return "Пожалуйста, укажите название задачи более подробно.\n\nНапример:\n• Создать задачу \"Подготовить презентацию\"\n• Добавить важную задачу \"Встреча с клиентом\"\n• Новая задача \"Планирование проекта\"\n• Нужно купить продукты завтра"
        }
        
        // Создаем реальную задачу
        let newTask = TaskItem(
            title: taskTitle,
            description: "Задача создана через AI чат: \(text)",
            status: status,
            priority: priority,
            dueDate: dueDate,
            tags: tags + ["ai-создана"],
            isPrivate: false,
            audioURL: nil,
            transcript: nil,
            createdAt: Date(),
            updatedAt: Date(),
            completedDate: nil,
            parentTaskId: nil,
            subtasks: []
        )
        
        homeViewModel.taskManager.addTask(newTask)
        
        var response = "✅ Задача успешно создана!\n\n📋 **\(taskTitle)**\n🎯 Приоритет: \(priority.displayName)\n📊 Статус: \(status.displayName)"
        
        if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            response += "\n📅 Срок: \(formatter.string(from: dueDate))"
        }
        
        if !tags.isEmpty {
            response += "\n🏷️ Теги: \(tags.joined(separator: ", "))"
        }
        
        response += "\n\nЗадача добавлена в раздел \"\(status.displayName)\" на главной странице."
        
        return response
    }
    
    // MARK: - Task Search
    private func searchTasksFromMessage(_ text: String) -> String {
        let allTasks = homeViewModel.taskManager.tasks
        
        if allTasks.isEmpty {
            return "📭 У вас пока нет созданных задач.\n\nПопробуйте создать первую задачу, написав:\n• \"Создать задачу \\\"Моя первая задача\\\"\""
        }
        
        var searchResults: [TaskItem] = []
        let lowercased = text.lowercased()
        
        // Поиск по ключевым словам
        if lowercased.contains("важн") || lowercased.contains("срочн") {
            searchResults = allTasks.filter { $0.priority == .high || $0.status == .important }
        } else if lowercased.contains("выполнен") || lowercased.contains("завершен") {
            searchResults = allTasks.filter { $0.status == .completed }
        } else if lowercased.contains("в процессе") || lowercased.contains("планах") {
            searchResults = allTasks.filter { $0.status == .planned }
        } else if lowercased.contains("застрял") || lowercased.contains("проблем") {
            searchResults = allTasks.filter { $0.status == .stuck }
        } else {
            // Общий поиск по названию
            searchResults = allTasks.filter { task in
                task.title.lowercased().contains(lowercased) ||
                (task.description?.lowercased().contains(lowercased) ?? false)
            }
        }
        
        if searchResults.isEmpty {
            return "🔍 По вашему запросу ничего не найдено.\n\nПопробуйте:\n• \"Показать все задачи\"\n• \"Найти важные задачи\"\n• \"Поиск выполненных задач\""
        }
        
        var response = "🔍 Найдено задач: \(searchResults.count)\n\n"
        
        for (index, task) in searchResults.prefix(5).enumerated() {
            let statusEmoji = getStatusEmoji(for: task.status)
            let priorityEmoji = getPriorityEmoji(for: task.priority)
            
            response += "\(index + 1). \(statusEmoji) **\(task.title)**\n"
            response += "   \(priorityEmoji) \(task.priority.displayName) • \(task.status.displayName)\n"
            
            if let description = task.description, !description.isEmpty {
                response += "   📝 \(description)\n"
            }
            
            if let dueDate = task.dueDate {
                response += "   📅 Срок: \(dueDate.formatted(date: .abbreviated, time: .omitted))\n"
            }
            
            response += "\n"
        }
        
        if searchResults.count > 5 {
            response += "... и еще \(searchResults.count - 5) задач"
        }
        
        return response
    }
    
    // MARK: - Show All Tasks
    private func showAllTasks() -> String {
        let allTasks = homeViewModel.taskManager.tasks
        
        if allTasks.isEmpty {
            return "📭 У вас пока нет созданных задач.\n\nСоздайте первую задачу, написав:\n• \"Создать задачу \\\"Моя первая задача\\\"\""
        }
        
        let groupedTasks = Dictionary(grouping: allTasks) { $0.status }
        var response = "📋 **Все ваши задачи** (\(allTasks.count))\n\n"
        
        for status in TaskStatus.allCases {
            if let tasks = groupedTasks[status], !tasks.isEmpty {
                let statusEmoji = getStatusEmoji(for: status)
                response += "\(statusEmoji) **\(status.displayName)** (\(tasks.count))\n"
                
                for task in tasks.prefix(3) {
                    let priorityEmoji = getPriorityEmoji(for: task.priority)
                    response += "   • \(priorityEmoji) \(task.title)\n"
                }
                
                if tasks.count > 3 {
                    response += "   ... и еще \(tasks.count - 3) задач\n"
                }
                
                response += "\n"
            }
        }
        
        return response
    }
    
    // MARK: - Productivity Analysis
    private func getProductivityAnalysis() -> String {
        let allTasks = homeViewModel.taskManager.tasks
        
        if allTasks.isEmpty {
            return "📊 **Анализ продуктивности**\n\nУ вас пока нет задач для анализа.\n\nСоздайте несколько задач, чтобы я мог показать статистику!"
        }
        
        let completedTasks = allTasks.filter { $0.status == .completed }
        let activeTasks = allTasks.filter { $0.status != .completed }
        let highPriorityTasks = allTasks.filter { $0.priority == .high }
        
        let completionRate = allTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(allTasks.count) * 100
        
        var response = "📊 **Анализ вашей продуктивности**\n\n"
        response += "📈 **Общая статистика:**\n"
        response += "• Всего задач: \(allTasks.count)\n"
        response += "• Выполнено: \(completedTasks.count)\n"
        response += "• В работе: \(activeTasks.count)\n"
        response += "• Процент выполнения: \(String(format: "%.1f", completionRate))%\n\n"
        
        response += "🎯 **По приоритетам:**\n"
        response += "• Высокий: \(highPriorityTasks.count)\n"
        response += "• Средний: \(allTasks.filter { $0.priority == .medium }.count)\n"
        response += "• Низкий: \(allTasks.filter { $0.priority == .low }.count)\n\n"
        
        response += "📊 **По статусам:**\n"
        for status in TaskStatus.allCases {
            let count = allTasks.filter { $0.status == status }.count
            if count > 0 {
                let emoji = getStatusEmoji(for: status)
                response += "• \(emoji) \(status.displayName): \(count)\n"
            }
        }
        
        return response
    }
    
    // MARK: - Productivity Recommendations
    private func getProductivityRecommendations() -> String {
        let allTasks = homeViewModel.taskManager.tasks
        let completedTasks = allTasks.filter { $0.status == .completed }
        let highPriorityTasks = allTasks.filter { $0.priority == .high && $0.status != .completed }
        
        var response = "💡 **Персональные рекомендации**\n\n"
        
        if allTasks.isEmpty {
            response += "🎯 **Начните с малого:**\n"
            response += "• Создайте первую задачу\n"
            response += "• Поставьте простую цель\n"
            response += "• Отмечайте прогресс\n\n"
        } else if completedTasks.count < 3 {
            response += "🚀 **Развивайте привычку:**\n"
            response += "• Выполняйте по одной задаче в день\n"
            response += "• Отмечайте каждое достижение\n"
            response += "• Создавайте простые задачи\n\n"
        } else if highPriorityTasks.count > 2 {
            response += "⚡ **Приоритизация:**\n"
            response += "• Сосредоточьтесь на важных задачах\n"
            response += "• Разбивайте большие задачи на мелкие\n"
            response += "• Делегируйте менее важное\n\n"
        } else {
            response += "🌟 **Оптимизация процесса:**\n"
            response += "• Используйте временные блоки\n"
            response += "• Анализируйте продуктивность\n"
            response += "• Планируйте на неделю вперед\n\n"
        }
        
        response += "🔧 **Общие советы:**\n"
        response += "• 🎯 Приоритизируйте задачи\n"
        response += "• ⏰ Выделяйте конкретное время\n"
        response += "• 📝 Разбивайте большие цели\n"
        response += "• 🔄 Регулярно анализируйте прогресс\n\n"
        
        response += "Хотите создать новую задачу или получить детальный анализ?"
        
        return response
    }
    
    // MARK: - Default Response
    private func getDefaultResponse() -> String {
        return "Интересный вопрос! Я могу помочь с:\n\n• 📋 **Управлением задачами** - создание, поиск, редактирование\n• 🔍 **Поиском информации** - найти задачи по критериям\n• 💡 **Планированием** - рекомендации по организации\n• 📊 **Анализом продуктивности** - статистика и тренды\n• 🎯 **Постановкой целей** - помощь в формулировке\n\nПопробуйте написать:\n• \"Создать задачу \\\"Подготовить отчет\\\"\"\n• \"Найти важные задачи\"\n• \"Показать все задачи\"\n• \"Дать рекомендации\""
    }
    
    // MARK: - Helper Methods
    private func getStatusEmoji(for status: TaskStatus) -> String {
        switch status {
        case .completed: return "✅"
        case .important: return "🔥"
        case .planned: return "📋"
        case .stuck: return "⚠️"
        case .paused: return "⏸️"
        case .waiting: return "⏳"
        case .delegated: return "👥"
        case .recurring: return "🔄"
        case .idea: return "💡"
        }
    }
    
    private func getPriorityEmoji(for priority: TaskPriority) -> String {
        switch priority {
        case .high: return "🔴"
        case .medium: return "🟡"
        case .low: return "🟢"
        }
    }
    
    func clearChat() {
        messages.removeAll()
        loadInitialMessage()
    }
    
    private func shouldCreateTask(from message: String) -> Bool {
        let lowercased = message.lowercased()
        let taskKeywords = [
            "поставь", "создай", "добавь", "задача", "нужно", "должен", "планирую",
            "хочу", "сделать", "завершить", "подготовить", "встретиться", "позвонить",
            "купить", "записаться", "изучить", "прочитать", "написать", "отправить"
        ]
        
        return taskKeywords.contains { lowercased.contains($0) }
    }
    
    private func createTaskFromAIResult(_ extractedTask: ExtractedTask) {
        let newTask = TaskItem(
            title: extractedTask.title,
            description: extractedTask.description ?? "Задача создана AI из чата",
            status: .planned,
            priority: extractedTask.priority,
            dueDate: extractedTask.dueDate,
            tags: extractedTask.tags + ["ai-создана", "чат"],
            isPrivate: false,
            audioURL: nil,
            transcript: nil,
            createdAt: Date(),
            updatedAt: Date(),
            completedDate: nil,
            parentTaskId: nil,
            subtasks: []
        )
        
        homeViewModel.taskManager.addTask(newTask)
        print("✅ Задача создана из чата: \(extractedTask.title)")
    }
}



#Preview {
    ChatView(homeViewModel: HomeViewModel())
}
