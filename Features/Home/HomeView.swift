import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingRecording = false
    @State private var selectedFilter: String?
    
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
            .background(Color.bone)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRecording) {
            RecordingView()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Current Date
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentDateString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.tobacco)
                
                Text(viewModel.currentDayString)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.espresso)
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
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.espresso)
                }
                
                Text("дней подряд")
                    .font(.system(size: 12))
                    .foregroundColor(.tobacco)
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
                showingRecording = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.cornflowerBlue)
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(viewModel.isRecordingButtonPulsing ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isRecordingButtonPulsing)
            
            Text(viewModel.recordingButtonText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.espresso)
                .multilineTextAlignment(.center)
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
                        tasks: viewModel.tasksForStatus(status),
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
                    .foregroundColor(.cornflowerBlue)
                
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
                .background(isSelected ? Color.cornflowerBlue : Color.linen)
                .cornerRadius(20)
        }
    }
}

#Preview {
    HomeView()
}
