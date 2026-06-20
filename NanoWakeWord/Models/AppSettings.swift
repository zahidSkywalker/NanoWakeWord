//
//  AppSettings.swift
//  NanoWakeWord
//
//  Persistent settings stored in UserDefaults.
//

import Foundation
import Combine

/// Manages all user-configurable app settings.
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Published Properties

    @Published var wakeWord: String {
        didSet { UserDefaults.standard.set(wakeWord, forKey: "wakeWord") }
    }

    @Published var sensitivity: Float {
        didSet { UserDefaults.standard.set(sensitivity, forKey: "sensitivity") }
    }

    @Published var isListening: Bool {
        didSet { UserDefaults.standard.set(isListening, forKey: "isListening") }
    }

    @Published var enableHaptics: Bool {
        didSet { UserDefaults.standard.set(enableHaptics, forKey: "enableHaptics") }
    }

    @Published var enableSound: Bool {
        didSet { UserDefaults.standard.set(enableSound, forKey: "enableSound") }
    }

    @Published var enableVoiceResponse: Bool {
        didSet { UserDefaults.standard.set(enableVoiceResponse, forKey: "enableVoiceResponse") }
    }

    @Published var voiceGender: String {
        didSet { UserDefaults.standard.set(voiceGender, forKey: "voiceGender") }
    }

    @Published var speakRate: Float {
        didSet { UserDefaults.standard.set(speakRate, forKey: "speakRate") }
    }

    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "language") }
    }

    @Published var autoStartListening: Bool {
        didSet { UserDefaults.standard.set(autoStartListening, forKey: "autoStartListening") }
    }

    @Published var commandTimeout: TimeInterval {
        didSet { UserDefaults.standard.set(commandTimeout, forKey: "commandTimeout") }
    }

    @Published var darkMode: Bool {
        didSet { UserDefaults.standard.set(darkMode, forKey: "darkMode") }
    }

    @Published var personality: AssistantPersonality {
        didSet {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(personality) {
                UserDefaults.standard.set(data, forKey: "personality")
            }
        }
    }

    @Published var notes: [NoteItem] {
        didSet {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(notes) {
                UserDefaults.standard.set(data, forKey: "notes")
            }
        }
    }

    @Published var reminders: [ReminderItem] {
        didSet {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(reminders) {
                UserDefaults.standard.set(data, forKey: "reminders")
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Initialize all stored properties first
        let sensitivityRaw = UserDefaults.standard.float(forKey: "sensitivity")
        self.sensitivity = sensitivityRaw == 0 ? 0.5 : sensitivityRaw
        self.wakeWord = UserDefaults.standard.string(forKey: "wakeWord") ?? "Hey Diana"
        self.isListening = UserDefaults.standard.bool(forKey: "isListening")
        self.enableHaptics = UserDefaults.standard.bool(forKey: "enableHaptics") ?? true
        self.enableSound = UserDefaults.standard.bool(forKey: "enableSound") ?? true
        self.enableVoiceResponse = UserDefaults.standard.bool(forKey: "enableVoiceResponse") ?? true
        self.voiceGender = UserDefaults.standard.string(forKey: "voiceGender") ?? "female"
        let speakRateRaw = UserDefaults.standard.float(forKey: "speakRate")
        self.speakRate = speakRateRaw == 0 ? 0.5 : speakRateRaw
        self.language = UserDefaults.standard.string(forKey: "language") ?? "en-US"
        self.autoStartListening = UserDefaults.standard.bool(forKey: "autoStartListening") ?? false
        let timeoutRaw = UserDefaults.standard.double(forKey: "commandTimeout")
        self.commandTimeout = timeoutRaw == 0 ? 5.0 : timeoutRaw
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode") ?? true

        if let data = UserDefaults.standard.data(forKey: "personality"),
           let personality = try? JSONDecoder().decode(AssistantPersonality.self, from: data) {
            self.personality = personality
        } else {
            self.personality = AssistantPersonality.default
        }

        if let data = UserDefaults.standard.data(forKey: "notes"),
           let notes = try? JSONDecoder().decode([NoteItem].self, from: data) {
            self.notes = notes
        } else {
            self.notes = []
        }

        if let data = UserDefaults.standard.data(forKey: "reminders"),
           let reminders = try? JSONDecoder().decode([ReminderItem].self, from: data) {
            self.reminders = reminders
        } else {
            self.reminders = []
        }
    }
}

// MARK: - Supporting Types

/// Represents the assistant's personality and voice style.
struct AssistantPersonality: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let greeting: String
    let style: VoiceStyle

    enum VoiceStyle: String, Codable, CaseIterable {
        case friendly    = "Friendly"
        case professional = "Professional"
        case playful     = "Playful"
        case calm        = "Calm"
        case witty       = "Witty"
    }

    static var `default`: AssistantPersonality {
        AssistantPersonality(
            id: UUID(),
            name: "Diana",
            description: "Friendly and helpful",
            greeting: "Hey there! How can I help you?",
            style: .friendly
        )
    }
}

/// A user note created via voice.
struct NoteItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    var isPinned: Bool

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.isPinned = false
    }
}

/// A reminder created via voice.
struct ReminderItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let triggerDate: Date?
    let isCompleted: Bool
    let createdAt: Date

    init(text: String, triggerDate: Date? = nil) {
        self.id = UUID()
        self.text = text
        self.triggerDate = triggerDate
        self.isCompleted = false
        self.createdAt = Date()
    }
}
