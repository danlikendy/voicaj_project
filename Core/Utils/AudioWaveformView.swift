import SwiftUI

struct AudioWaveformView: View {
    let audioLevel: Float
    let isRecording: Bool
    let isPaused: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    private let numberOfBars = 20
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    
    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                AudioBar(
                    index: index,
                    audioLevel: audioLevel,
                    isRecording: isRecording,
                    isPaused: isPaused,
                    animationPhase: animationPhase
                )
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
    
    private func stopAnimation() {
        animationPhase = 0
    }
}

struct AudioBar: View {
    let index: Int
    let audioLevel: Float
    let isRecording: Bool
    let isPaused: Bool
    let animationPhase: CGFloat
    
    private let maxHeight: CGFloat = 60
    private let minHeight: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barColor)
            .frame(width: 3, height: barHeight)
            .animation(.easeInOut(duration: 0.1), value: barHeight)
    }
    
    private var barHeight: CGFloat {
        if !isRecording {
            return minHeight
        }
        
        if isPaused {
            return currentHeight * 0.5
        }
        
        // Базовая высота на основе уровня аудио
        let baseHeight = CGFloat(audioLevel + 60) / 60 * maxHeight
        
        // Добавляем случайность для естественности
        let randomFactor = CGFloat.random(in: 0.7...1.3)
        
        // Добавляем волновой эффект
        let waveEffect = sin((animationPhase * 2 * .pi) + Double(index) * 0.3) * 10
        
        let finalHeight = (baseHeight * randomFactor) + waveEffect
        
        return max(minHeight, min(maxHeight, finalHeight))
    }
    
    private var currentHeight: CGFloat {
        if !isRecording {
            return minHeight
        }
        
        // Создаем волновой паттерн
        let baseHeight = CGFloat(audioLevel + 60) / 60 * maxHeight
        let waveOffset = sin(Double(index) * 0.5 + animationPhase * 2 * .pi) * 15
        
        return max(minHeight, min(maxHeight, baseHeight + waveOffset))
    }
    
    private var barColor: Color {
        if !isRecording {
            return .gray.opacity(0.3)
        }
        
        if isPaused {
            return .orange.opacity(0.6)
        }
        
        // Цвет зависит от уровня аудио
        let normalizedLevel = (audioLevel + 60) / 60
        
        if normalizedLevel > 0.7 {
            return .red
        } else if normalizedLevel > 0.4 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AudioWaveformView(
            audioLevel: -20,
            isRecording: true,
            isPaused: false
        )
        
        AudioWaveformView(
            audioLevel: -40,
            isRecording: true,
            isPaused: true
        )
        
        AudioWaveformView(
            audioLevel: 0,
            isRecording: false,
            isPaused: false
        )
    }
    .padding()
    .background(Color.black)
}
