import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var selectedFilter: String?
    @State private var filteredTasks: [TaskItem] = []
    
    // MARK: - Recording Functions
    private func startRecording() {
        isRecording = true
        recordingTime = 0
        
        // Запускаем таймер
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingTime += 1
        }
        
        // TODO: Здесь будет реальная запись аудио
        print("🎤 Начало записи")
    }
    
    private func stopRecording() {
        isRecording = false
        
        // Останавливаем таймер
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // TODO: Здесь будет остановка записи и анализ
        print("⏹️ Остановка записи")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Main Recording Button
                    mainRecordingButton
                    
                    // Quick Actions
                    quickActionsView
                    
                    // Task Lists
                    taskListsView
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .refreshable {
                // Обновляем данные при pull-to-refresh
                await refreshData()
            }
            .tint(.espresso) // Исправляем цвет иконки обновления
            .onAppear {
                // Инициализируем отфильтрованные задачи
                filteredTasks = viewModel.tasks
            }
            .onChange(of: selectedFilter) { _, newFilter in
                if let filter = newFilter {
                    filteredTasks = viewModel.tasks.filter { task in
                        task.tags.contains { tag in
                            tag.lowercased().contains(filter.lowercased())
                        }
                    }
                } else {
                    filteredTasks = viewModel.tasks
                }
            }
            .overlay(
                // Верхний градиент для плавного перехода
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.bone.opacity(0.98),
                            Color.bone.opacity(0.9),
                            Color.bone.opacity(0.7),
                            Color.bone.opacity(0.4),
                            Color.bone.opacity(0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    Spacer()
                }
                .allowsHitTesting(false) // Чтобы градиент не блокировал нажатия
                .ignoresSafeArea(.all, edges: .top) // Игнорируем safe area сверху
            )
            .background(Color.bone)
            .navigationBarHidden(true)
        }

    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Current Date
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentDateString)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.espresso)
                
                Text("Сегодня")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.tobacco)
            }
            
            Spacer()
            
            // Greeting
            VStack(alignment: .center, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.espresso)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Streak Indicator
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.honeyGold)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.currentStreak)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.espresso)
                        
                        Text("дней")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.tobacco)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.porcelain)
        .cornerRadius(20)
    }
    
    // MARK: - Main Recording Button
    private var mainRecordingButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.terracotta : Color.honeyGold)
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(viewModel.isRecordingButtonPulsing ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isRecordingButtonPulsing)
            
            if isRecording {
                Text(formatTime(recordingTime))
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.espresso)
                    .multilineTextAlignment(.center)
            } else {
                Text("Запишите итог дня")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.espresso)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Быстрые действия")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.espresso)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                        ForEach(VoiceTemplate.allCases.prefix(3), id: \.self) { template in
                            QuickActionCard(template: template) {
                                // TODO: Open recording with template
                                print("🚀 Быстрое действие: \(template.displayName)")
                                // В будущем здесь будет открытие экрана записи с шаблоном
                                // Согласно плану: "Быстрые действия → экран «Запись» с предустановленным шаблоном"
                                
                                // Пока что просто показываем сообщение о выбранном шаблоне
                                // TODO: Добавить переход на экран записи с выбранным шаблоном
                            }
                        }
            }
        }
    }
    
    // MARK: - Task Lists
    private var taskListsView: some View {
        VStack(spacing: 20) {
            // Filters
            filterChipsView
            
            // Task Sections
            LazyVStack(spacing: 16) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    TaskSectionView(
                        status: status,
                        tasks: selectedFilter != nil ? 
                            filteredTasks.filter { $0.status == status } : 
                            viewModel.tasksForStatus(status),
                        isCollapsed: viewModel.collapsedSections.contains(status)
                    ) {
                        viewModel.toggleSection(status)
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Chips
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.availableTags, id: \.self) { tag in
                    FilterChip(
                        tag: tag,
                        isSelected: selectedFilter == tag
                    ) {
                        if selectedFilter == tag {
                            selectedFilter = nil
                        } else {
                            selectedFilter = tag
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let template: VoiceTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.honeyGold)
                
                Text(template.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.espresso)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color.porcelain)
            .cornerRadius(16)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("#\(tag)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .espresso)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.honeyGold : Color.linen)
                .cornerRadius(20)
        }
    }
}

// MARK: - Data Refresh
extension HomeView {
    private func refreshData() async {
        // Имитируем задержку обновления
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // Обновляем отфильтрованные задачи
            filteredTasks = viewModel.tasks
            print("🔄 Данные обновлены")
        }
    }
}

#Preview {
    HomeView()
}
