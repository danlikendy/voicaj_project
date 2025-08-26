import SwiftUI

struct ColorPalette {
    
    // MARK: - Light Theme (Warm Light)
    struct Light {
        // Нейтральные тона
        static let background = Color(red: 0.98, green: 0.96, blue: 0.92) // Bone - теплый белый
        static let surface = Color(red: 0.95, green: 0.93, blue: 0.89) // Porcelain - кремовый
        static let surfaceAlt = Color(red: 0.97, green: 0.95, blue: 0.91) // Linen - льняной
        static let textPrimary = Color(red: 0.2, green: 0.15, blue: 0.1) // Espresso - темно-коричневый
        static let textSecondary = Color(red: 0.4, green: 0.35, blue: 0.3) // Tobacco - коричневый
        static let divider = Color(red: 0.9, green: 0.88, blue: 0.84) // Parchment - пергамент
        
        // Акценты по статусам
        static let mossGreen = Color(red: 0.2, green: 0.6, blue: 0.3) // MossGreen - мшисто-зеленый
        static let terracotta = Color(red: 0.8, green: 0.4, blue: 0.3) // Terracotta - терракотовый
        static let honeyGold = Color(red: 0.9, green: 0.7, blue: 0.2) // HoneyGold - медово-золотой
        static let cornflowerBlue = Color(red: 0.4, green: 0.6, blue: 0.9) // CornflowerBlue - васильковый
        static let orchidPurple = Color(red: 0.7, green: 0.4, blue: 0.8) // OrchidPurple - орхидейный
        static let warmGrey = Color(red: 0.6, green: 0.55, blue: 0.5) // WarmGrey - теплый серый
        static let tealMist = Color(red: 0.3, green: 0.6, blue: 0.6) // TealMist - бирюзовый туман
        static let olive = Color(red: 0.5, green: 0.6, blue: 0.3) // Olive - оливковый
        static let mint = Color(red: 0.4, green: 0.8, blue: 0.6) // Mint - мятный
    }
    
    // MARK: - Dark Theme (Cocoa Dark)
    struct Dark {
        // Нейтральные тона
        static let background = Color(red: 0.1, green: 0.08, blue: 0.06) // Cocoa - темно-коричневый
        static let surface = Color(red: 0.15, green: 0.12, blue: 0.1) // Mocha - мокко
        static let surfaceAlt = Color(red: 0.12, green: 0.1, blue: 0.08) // Cacao - какао
        static let textPrimary = Color(red: 0.95, green: 0.93, blue: 0.91) // LinenLight - светлый лен
        static let textSecondary = Color(red: 0.7, green: 0.65, blue: 0.6) // Taupe - серо-коричневый
        static let divider = Color(red: 0.2, green: 0.17, blue: 0.15) // MochaLine - линия мокко
        
        // Акценты по статусам (осветлённые версии)
        static let mossTint = Color(red: 0.4, green: 0.8, blue: 0.5) // MossTint - светлый мшисто-зеленый
        static let terracottaTint = Color(red: 0.9, green: 0.6, blue: 0.5) // TerracottaTint - светлый терракотовый
        static let honeyTint = Color(red: 1.0, green: 0.8, blue: 0.4) // HoneyTint - светлый медово-золотой
        static let cornflowerTint = Color(red: 0.6, green: 0.8, blue: 1.0) // CornflowerTint - светлый васильковый
        static let orchidTint = Color(red: 0.9, green: 0.6, blue: 1.0) // OrchidTint - светлый орхидейный
        static let warmGreyTint = Color(red: 0.8, green: 0.75, blue: 0.7) // WarmGreyTint - светлый теплый серый
        static let tealTint = Color(red: 0.5, green: 0.8, blue: 0.8) // TealTint - светлый бирюзовый
        static let oliveTint = Color(red: 0.7, green: 0.8, blue: 0.5) // OliveTint - светлый оливковый
        static let mintTint = Color(red: 0.6, green: 1.0, blue: 0.8) // MintTint - светлый мятный
    }
    
    // MARK: - Status Colors
    static func statusColor(for status: TaskStatus, isDarkMode: Bool = false) -> Color {
        if isDarkMode {
            switch status {
            case .completed: return Dark.mossTint
            case .important: return Dark.orchidTint
            case .planned: return Dark.cornflowerTint
            case .stuck: return Dark.terracottaTint
            case .paused: return Dark.honeyTint
            case .waiting: return Dark.tealTint
            case .delegated: return Dark.oliveTint
            case .recurring: return Dark.mintTint
            case .idea: return Dark.warmGreyTint
            }
        } else {
            switch status {
            case .completed: return Light.mossGreen
            case .important: return Light.orchidPurple
            case .planned: return Light.cornflowerBlue
            case .stuck: return Light.terracotta
            case .paused: return Light.honeyGold
            case .waiting: return Light.tealMist
            case .delegated: return Light.olive
            case .recurring: return Light.mint
            case .idea: return Light.warmGrey
            }
        }
    }
    
    // MARK: - Priority Colors
    static func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    // MARK: - Additional Colors
    static func additionalColor(for name: String) -> Color {
        switch name {
        case "honeyGold": return Light.honeyGold
        case "terracotta": return Light.terracotta
        default: return .gray
        }
    }
    
    // MARK: - Mood Colors
    static func moodColor(for mood: Mood, isDarkMode: Bool = false) -> Color {
        if isDarkMode {
            switch mood {
            case .calm: return Dark.mossTint
            case .energetic: return Dark.honeyTint
            case .stressed: return Dark.terracottaTint
            case .happy: return Dark.mintTint
            case .tired: return Dark.warmGreyTint
            case .focused: return Dark.cornflowerTint
            }
        } else {
            switch mood {
            case .calm: return Light.mossGreen
            case .energetic: return Light.honeyGold
            case .stressed: return Light.terracotta
            case .happy: return Light.mint
            case .tired: return Light.warmGrey
            case .focused: return Light.cornflowerBlue
            }
        }
    }
}

// MARK: - Color Extensions
extension Color {
    // MARK: - Light Theme Colors
    static let bone = ColorPalette.Light.background
    static let porcelain = ColorPalette.Light.surface
    static let linen = ColorPalette.Light.surfaceAlt
    static let espresso = ColorPalette.Light.textPrimary
    static let tobacco = ColorPalette.Light.textSecondary
    static let parchment = ColorPalette.Light.divider
    
    // MARK: - Status Colors (Light)
    static let mossGreen = ColorPalette.Light.mossGreen
    static let terracotta = ColorPalette.Light.terracotta
    static let honeyGold = ColorPalette.Light.honeyGold
    static let cornflowerBlue = ColorPalette.Light.cornflowerBlue
    static let orchidPurple = ColorPalette.Light.orchidPurple
    static let warmGrey = ColorPalette.Light.warmGrey
    static let tealMist = ColorPalette.Light.tealMist
    static let olive = ColorPalette.Light.olive
    static let mint = ColorPalette.Light.mint
    
    // MARK: - Dark Theme Colors
    static let cocoa = ColorPalette.Dark.background
    static let mocha = ColorPalette.Dark.surface
    static let cacao = ColorPalette.Dark.surfaceAlt
    static let linenLight = ColorPalette.Dark.textPrimary
    static let taupe = ColorPalette.Dark.textSecondary
    static let mochaLine = ColorPalette.Dark.divider
    
    // MARK: - Status Colors (Dark)
    static let mossTint = ColorPalette.Dark.mossTint
    static let terracottaTint = ColorPalette.Dark.terracottaTint
    static let honeyTint = ColorPalette.Dark.honeyTint
    static let cornflowerTint = ColorPalette.Dark.cornflowerTint
    static let orchidTint = ColorPalette.Dark.orchidTint
    static let warmGreyTint = ColorPalette.Dark.warmGreyTint
    static let tealTint = ColorPalette.Dark.tealTint
    static let oliveTint = ColorPalette.Dark.oliveTint
    static let mintTint = ColorPalette.Dark.mintTint
}
