import SwiftUI

struct ColorPalette {
    
    // MARK: - Light Theme (Warm Light)
    struct Light {
        // Нейтральные тона
        static let background = Color("Bone")
        static let surface = Color("Porcelain")
        static let surfaceAlt = Color("Linen")
        static let textPrimary = Color("Espresso")
        static let textSecondary = Color("Tobacco")
        static let divider = Color("Parchment")
        
        // Акценты по статусам
        static let mossGreen = Color("MossGreen")           // Свершилось
        static let terracotta = Color("Terracotta")         // Застряло
        static let honeyGold = Color("HoneyGold")           // На паузе
        static let cornflowerBlue = Color("CornflowerBlue") // В планах
        static let orchidPurple = Color("OrchidPurple")     // Важное
        static let warmGrey = Color("WarmGrey")             // Идеи
        static let tealMist = Color("TealMist")             // Ожидает ответа
        static let olive = Color("Olive")                   // Делегировано
        static let mint = Color("Mint")                     // Повторяющееся
    }
    
    // MARK: - Dark Theme (Cocoa Dark)
    struct Dark {
        // Нейтральные тона
        static let background = Color("Cocoa")
        static let surface = Color("Mocha")
        static let surfaceAlt = Color("Cacao")
        static let textPrimary = Color("LinenLight")
        static let textSecondary = Color("Taupe")
        static let divider = Color("MochaLine")
        
        // Акценты по статусам (осветлённые версии)
        static let mossTint = Color("MossTint")
        static let terracottaTint = Color("TerracottaTint")
        static let honeyTint = Color("HoneyTint")
        static let cornflowerTint = Color("CornflowerTint")
        static let orchidTint = Color("OrchidTint")
        static let warmGreyTint = Color("WarmGreyTint")
        static let tealTint = Color("TealTint")
        static let oliveTint = Color("OliveTint")
        static let mintTint = Color("MintTint")
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
        case "honeyGold": return Color("HoneyGold")
        case "terracotta": return Color("Terracotta")
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
    static let bone = Color("Bone")
    static let porcelain = Color("Porcelain")
    static let linen = Color("Linen")
    static let espresso = Color("Espresso")
    static let tobacco = Color("Tobacco")
    static let parchment = Color("Parchment")
    
    // MARK: - Status Colors (Light)
    static let mossGreen = Color("MossGreen")
    static let terracotta = Color("Terracotta")
    static let honeyGold = Color("HoneyGold")
    static let cornflowerBlue = Color("CornflowerBlue")
    static let orchidPurple = Color("OrchidPurple")
    static let warmGrey = Color("WarmGrey")
    static let tealMist = Color("TealMist")
    static let olive = Color("Olive")
    static let mint = Color("Mint")
    
    // MARK: - Dark Theme Colors
    static let cocoa = Color("Cocoa")
    static let mocha = Color("Mocha")
    static let cacao = Color("Cacao")
    static let linenLight = Color("LinenLight")
    static let taupe = Color("Taupe")
    static let mochaLine = Color("MochaLine")
    
    // MARK: - Status Colors (Dark)
    static let mossTint = Color("MossTint")
    static let terracottaTint = Color("TerracottaTint")
    static let honeyTint = Color("HoneyTint")
    static let cornflowerTint = Color("CornflowerTint")
    static let orchidTint = Color("OrchidTint")
    static let warmGreyTint = Color("WarmGreyTint")
    static let tealTint = Color("TealTint")
    static let oliveTint = Color("OliveTint")
    static let mintTint = Color("MintTint")
}
