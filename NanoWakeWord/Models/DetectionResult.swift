//
//  DetectionResult.swift
//  NanoWakeWord
//
//  Data model for wake word detection events.
//

import Foundation

/// Represents a single wake word detection event.
struct DetectionResult: Identifiable, Codable {
    let id: UUID
    let wakeWord: String
    let timestamp: Date
    let commandText: String?
    let responseText: String?
    let commandType: CommandType?
    let confidence: Float

    init(
        id: UUID = UUID(),
        wakeWord: String,
        timestamp: Date = Date(),
        commandText: String? = nil,
        responseText: String? = nil,
        commandType: CommandType? = nil,
        confidence: Float = 1.0
    ) {
        self.id = id
        self.wakeWord = wakeWord
        self.timestamp = timestamp
        self.commandText = commandText
        self.responseText = responseText
        self.commandType = commandType
        self.confidence = confidence
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
}

/// Types of voice commands the assistant can handle.
enum CommandType: String, Codable, CaseIterable {
    case math            = "Math"
    case weather         = "Weather"
    case time            = "Time"
    case date            = "Date"
    case note            = "Note"
    case reminder        = "Reminder"
    case joke            = "Joke"
    case fact            = "Fact"
    case timer           = "Timer"
    case openApp         = "Open App"
    case brightness      = "Brightness"
    case volume          = "Volume"
    case translation     = "Translation"
    case define          = "Define"
    case calculate       = "Calculate"
    case general         = "General"
    case unknown         = "Unknown"

    var icon: String {
        switch self {
        case .math:       return "function"
        case .weather:    return "cloud.sun"
        case .time:       return "clock"
        case .date:       return "calendar"
        case .note:       return "note.text"
        case .reminder:   return "bell"
        case .joke:       return "face.smiling"
        case .fact:       return "lightbulb"
        case .timer:      return "timer"
        case .openApp:    return "app"
        case .brightness: return "sun.max"
        case .volume:     return "speaker.wave.2"
        case .translation:return "globe"
        case .define:     return "book"
        case .calculate:  return "number.square"
        case .general:    return "bubble.left"
        case .unknown:    return "questionmark"
        }
    }

    var color: String {
        switch self {
        case .math:       return "purple"
        case .weather:    return "blue"
        case .time, .date:return "orange"
        case .note:       return "yellow"
        case .reminder:   return "red"
        case .joke:       return "green"
        case .fact:       return "cyan"
        case .timer:      return "indigo"
        case .openApp:    return "mint"
        case .brightness: return "yellow"
        case .volume:     return "teal"
        case .translation:return "blue"
        case .define:     return "brown"
        case .calculate:  return "pink"
        case .general:    return "gray"
        case .unknown:    return "gray"
        }
    }
}
