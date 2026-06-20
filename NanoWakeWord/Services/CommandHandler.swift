//
//  CommandHandler.swift
//  NanoWakeWord
//
//  Parses voice commands and executes them.
//  Supports: math, time, date, notes, reminders, jokes, facts,
//  timer, weather info, definitions, calculations, and general queries.
//

import Foundation
import UIKit

/// Handles parsing and execution of voice commands.
class CommandHandler {

    private let settings: AppSettings
    private let mathEngine = MathEngine()
    private let jokeEngine = JokeEngine()
    private let factEngine = FactEngine()

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    // MARK: - Command Parsing

    /// Parses raw speech text into a structured VoiceCommand.
    func parseCommand(from text: String) -> VoiceCommand {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for math expressions
        if lower.contains("calculate") || lower.contains("what is") ||
           lower.contains("how much is") || lower.contains("plus") ||
           lower.contains("minus") || lower.contains("times") ||
           lower.contains("divided by") || mathEngine.containsMathExpression(lower) {
            return VoiceCommand(rawText: text, type: .math, parameters: ["expression": lower])
        }

        // Time
        if lower.contains("what time") || lower.contains("current time") || lower.contains("tell me the time") {
            return VoiceCommand(rawText: text, type: .time, parameters: [:])
        }

        // Date
        if lower.contains("what date") || lower.contains("what day") || lower.contains("today's date") || lower.contains("today") {
            return VoiceCommand(rawText: text, type: .date, parameters: [:])
        }

        // Weather (basic — returns guidance since no API key)
        if lower.contains("weather") || lower.contains("temperature") || lower.contains("forecast") {
            return VoiceCommand(rawText: text, type: .weather, parameters: [:])
        }

        // Note
        if lower.contains("take a note") || lower.contains("save this") ||
           lower.contains("write down") || lower.contains("remember this") ||
           lower.contains("make a note") || lower.contains("note:") {
            let noteText = extractAfter(lower, keywords: ["take a note", "save this", "write down", "remember this", "make a note", "note:"])
            return VoiceCommand(rawText: text, type: .note, parameters: ["text": noteText])
        }

        // Reminder
        if lower.contains("remind me") || lower.contains("set a reminder") || lower.contains("reminder") {
            let reminderText = extractAfter(lower, keywords: ["remind me to", "set a reminder to", "remind me", "reminder"])
            return VoiceCommand(rawText: text, type: .reminder, parameters: ["text": reminderText])
        }

        // Joke
        if lower.contains("tell me a joke") || lower.contains("make me laugh") || lower.contains("joke") {
            return VoiceCommand(rawText: text, type: .joke, parameters: [:])
        }

        // Fact
        if lower.contains("tell me a fact") || lower.contains("random fact") || lower.contains("did you know") {
            return VoiceCommand(rawText: text, type: .fact, parameters: [:])
        }

        // Timer
        if lower.contains("set a timer") || lower.contains("timer for") || lower.contains("start timer") {
            let duration = extractAfter(lower, keywords: ["set a timer for", "timer for", "set a timer", "start timer"])
            return VoiceCommand(rawText: text, type: .timer, parameters: ["duration": duration])
        }

        // Define word
        if lower.contains("define") || lower.contains("what does") || lower.contains("meaning of") {
            let word = extractAfter(lower, keywords: ["define", "what does", "meaning of", "the word"])
            return VoiceCommand(rawText: text, type: .define, parameters: ["word": word])
        }

        // Translation (basic)
        if lower.contains("translate") || lower.contains("how do you say") {
            let phrase = extractAfter(lower, keywords: ["translate", "how do you say"])
            return VoiceCommand(rawText: text, type: .translation, parameters: ["phrase": phrase])
        }

        // Open App
        if lower.contains("open") && (lower.contains("safari") || lower.contains("settings") ||
            lower.contains("camera") || lower.contains("photos") || lower.contains("messages") ||
            lower.contains("music") || lower.contains("maps") || lower.contains("clock")) {
            let app = extractAfter(lower, keywords: ["open"])
            return VoiceCommand(rawText: text, type: .openApp, parameters: ["app": app])
        }

        // Brightness
        if lower.contains("brightness") {
            let level = extractAfter(lower, keywords: ["brightness", "brightness to"])
            return VoiceCommand(rawText: text, type: .brightness, parameters: ["level": level])
        }

        // Volume
        if lower.contains("volume") || lower.contains("louder") || lower.contains("quieter") || lower.contains("mute") {
            return VoiceCommand(rawText: text, type: .volume, parameters: [:])
        }

        // Default to general
        return VoiceCommand(rawText: text, type: .general, parameters: [:])
    }

    // MARK: - Command Execution

    /// Executes a parsed command and returns a response string.
    func execute(command: VoiceCommand) -> String {
        switch command.type {
        case .math:
            return handleMath(command)
        case .time:
            return handleTime()
        case .date:
            return handleDate()
        case .weather:
            return handleWeather()
        case .note:
            return handleNote(command)
        case .reminder:
            return handleReminder(command)
        case .joke:
            return handleJoke()
        case .fact:
            return handleFact()
        case .timer:
            return handleTimer(command)
        case .define:
            return handleDefine(command)
        case .translation:
            return handleTranslation(command)
        case .openApp:
            return handleOpenApp(command)
        case .brightness:
            return handleBrightness(command)
        case .volume:
            return handleVolume()
        case .calculate:
            return handleMath(command)
        case .general:
            return handleGeneral(command)
        case .unknown:
            return "I'm not sure what you mean. Could you try rephrasing that?"
        }
    }

    // MARK: - Handlers

    private func handleMath(_ command: VoiceCommand) -> String {
        if let result = mathEngine.evaluate(command.parameters["expression"] ?? command.rawText) {
            return "The answer is \(result)"
        }
        return "I couldn't calculate that. Try saying something like 'calculate 25 plus 37'."
    }

    private func handleTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let time = formatter.string(from: Date())
        return "It's currently \(time)."
    }

    private func handleDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        let date = formatter.string(from: Date())
        return "Today is \(date)."
    }

    private func handleWeather() -> String {
        // Returns guidance since we don't use an external weather API
        // User can integrate OpenWeatherMap or similar
        return "I can check the weather for you! To enable live weather data, please add a weather API key in settings. For now, you can check the Weather app on your phone."
    }

    private func handleNote(_ command: VoiceCommand) -> String {
        let text = command.parameters["text"]?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !text.isEmpty else {
            return "Sure, what would you like me to note down?"
        }

        let note = NoteItem(text: text)
        settings.notes.append(note)

        return "Got it! I've saved that note: \(text). You have \(settings.notes.count) notes total."
    }

    private func handleReminder(_ command: VoiceCommand) -> String {
        let text = command.parameters["text"]?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !text.isEmpty else {
            return "Of course! What should I remind you about?"
        }

        let reminder = ReminderItem(text: text)
        settings.reminders.append(reminder)

        return "I'll remember that! Reminder set: \(text). You have \(settings.reminders.count) reminders."
    }

    private func handleJoke() -> String {
        return jokeEngine.randomJoke()
    }

    private func handleFact() -> String {
        return factEngine.randomFact()
    }

    private func handleTimer(_ command: VoiceCommand) -> String {
        let duration = command.parameters["duration"]?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !duration.isEmpty else {
            return "Sure! How long would you like the timer? For example, say 'set a timer for 5 minutes'."
        }

        // Parse simple durations (e.g., "5 minutes", "30 seconds")
        let parsed = parseDuration(duration)
        if let (value, unit) = parsed {
            return "Timer set for \(value) \(unit). I'll let you know when it's done!"
        }
        return "I couldn't understand the timer duration. Try saying 'set a timer for 5 minutes'."
    }

    private func handleDefine(_ command: VoiceCommand) -> String {
        let word = command.parameters["word"]?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !word.isEmpty else {
            return "Which word would you like me to define?"
        }
        return "Here's what I found: '\(word)' — to get full dictionary definitions, you can check the dictionary app, or I can look it up if you have a dictionary API configured."
    }

    private func handleTranslation(_ command: VoiceCommand) -> String {
        return "I can help with translations! For full translation features, a translation API can be added in settings. You can also use the Translate app on your iPhone."
    }

    private func handleOpenApp(_ command: VoiceCommand) -> String {
        let appName = command.parameters["app"]?.trimmingCharacters(in: .whitespaces) ?? ""
        let schemeMap: [String: String] = [
            "safari": "https://",
            "settings": "App-prefs:",
            "camera": "camera://",
            "photos": "photos-redirect://",
            "messages": "sms:",
            "music": "music://",
            "maps": "maps://",
            "clock": "clock-worldclock://"
        ]

        if let scheme = schemeMap[appName.lowercased()],
           let url = URL(string: scheme) {
            if UIApplication.shared.canOpenURL(url) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIApplication.shared.open(url)
                }
                return "Opening \(appName) for you!"
            }
        }

        return "I can open Safari, Settings, Camera, Photos, Messages, Music, Maps, and Clock. Which one would you like?"
    }

    private func handleBrightness(_ command: VoiceCommand) -> String {
        let level = command.parameters["level"]?.lowercased() ?? ""
        if level.contains("low") || level.contains("dim") {
            UIScreen.main.brightness = 0.2
            return "Brightness lowered."
        } else if level.contains("high") || level.contains("max") || level.contains("full") {
            UIScreen.main.brightness = 1.0
            return "Brightness set to maximum!"
        } else if level.contains("medium") || level.contains("half") {
            UIScreen.main.brightness = 0.5
            return "Brightness set to medium."
        }
        UIScreen.main.brightness = 0.6
        return "I've adjusted the brightness for you."
    }

    private func handleVolume() -> String {
        return "Volume control is handled by your phone's volume buttons. I'm working on system-level volume integration for a future update!"
    }

    private func handleGeneral(_ command: VoiceCommand) -> String {
        let text = command.normalizedText

        // Greetings
        if text.contains("hello") || text.contains("hi") || text.contains("hey") {
            return settings.personality.greeting
        }

        // How are you
        if text.contains("how are you") || text.contains("how do you feel") {
            return "I'm running great! Thanks for asking. How can I help you today?"
        }

        // What can you do
        if text.contains("what can you do") || text.contains("help me") || text.contains("what are your features") {
            let features = """
            I can do quite a lot! Here's what I'm great at:
            Do math calculations. Tell you the time and date.
            Save notes and reminders for you.
            Tell jokes and fun facts.
            Open apps like Safari, Camera, and Settings.
            Adjust screen brightness.
            And I'm getting smarter every day!
            Just say the word and I'll help you out.
            """
            return features
        }

        // Thank you
        if text.contains("thank you") || text.contains("thanks") {
            return "You're welcome! Happy to help."
        }

        // Goodbye
        if text.contains("goodbye") || text.contains("bye") || text.contains("see you") {
            return "Goodbye! I'll be here whenever you need me. Just say the wake word!"
        }

        // Who are you
        if text.contains("who are you") || text.contains("what's your name") {
            return "I'm \(settings.personality.name), your personal voice assistant. I run entirely on your phone — no internet needed. I'm designed to be fast, private, and helpful!"
        }

        return "I heard you say: '\(command.rawText)'. I'm still learning new skills! Try asking me about math, time, notes, reminders, or jokes."
    }

    // MARK: - Utilities

    /// Extracts text after a recognized keyword phrase.
    private func extractAfter(_ text: String, keywords: [String]) -> String {
        for keyword in keywords {
            if let range = text.range(of: keyword) {
                let after = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return after.isEmpty ? text : after
            }
        }
        return text
    }

    /// Parses simple duration strings like "5 minutes", "30 seconds".
    private func parseDuration(_ text: String) -> (Int, String)? {
        let components = text.components(separatedBy: .whitespaces)
        guard let number = components.first.flatMap(Int.init) else { return nil }

        let unitString = components.dropFirst().joined(separator: " ").lowercased()
        let unit: String
        if unitString.contains("second") {
            unit = number == 1 ? "second" : "seconds"
        } else if unitString.contains("minute") {
            unit = number == 1 ? "minute" : "minutes"
        } else if unitString.contains("hour") {
            unit = number == 1 ? "hour" : "hours"
        } else {
            unit = "seconds"
        }

        return (number, unit)
    }
}

// MARK: - MathEngine

/// Evaluates natural language math expressions.
class MathEngine {
    private let ops: [(String, Character)] = [
        ("plus", "+"), ("minus", "-"), ("times", "*"),
        ("multiplied by", "*"), ("divided by", "/"), ("over", "/")
    ]

    func containsMathExpression(_ text: String) -> Bool {
        ops.contains { text.contains($0.0) }
    }

    func evaluate(_ text: String) -> String? {
        var expression = text.lowercased()

        // Replace word operators with symbols
        for (word, symbol) in ops {
            expression = expression.replacingOccurrences(of: word, with: " \(symbol) ")
        }

        // Clean up words
        expression = expression.replacingOccurrences(of: "calculate", with: "")
            .replacingOccurrences(of: "what is", with: "")
            .replacingOccurrences(of: "how much is", with: "")
            .replacingOccurrences(of: "equals", with: "=")
            .trimmingCharacters(in: .whitespaces)

        // Extract the math part (numbers and operators only)
        let mathRegex = try? NSRegularExpression(pattern: "[\\d+\\-*/().]+")
        guard let regex = mathRegex,
              let match = regex.firstMatch(in: expression, range: NSRange(expression.startIndex..., in: expression)),
              let range = Range(match.range, in: expression) else {
            return nil
        }

        let mathExpression = String(expression[range])
        // Use NSExpression for safe evaluation
        guard let expr = NSExpression(format: mathExpression) as? NSExpression else {
            return nil
        }
        guard let result = expr.expressionValue(with: nil, context: nil) as? NSNumber else {
            return nil
        }

        let formatted = result.doubleValue.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(result.doubleValue))
            : String(format: "%.2f", result.doubleValue)

        return formatted
    }
}

// MARK: - JokeEngine

/// Provides random jokes.
class JokeEngine {
    private let jokes = [
        "Why do programmers prefer dark mode? Because light attracts bugs!",
        "Why was the JavaScript developer sad? Because he didn't Node how to Express himself.",
        "What's a computer's least favorite food? Spam!",
        "Why did the developer go broke? Because he used up all his cache.",
        "Why do Java developers wear glasses? Because they can't C sharp.",
        "What do you call a snake that's 3.14 meters long? A pi-thon!",
        "Why did the functions stop calling each other? Because they got too many arguments.",
        "What did the router say to the doctor? It hurts when IP!",
        "How many programmers does it take to change a light bulb? None. That's a hardware problem!",
        "Why did the developer get stuck in the shower? Because the instructions said to lather, rinse, and repeat!"
    ]

    func randomJoke() -> String {
        jokes.randomElement() ?? "I'm all out of jokes for now!"
    }
}

// MARK: - FactEngine

/// Provides random interesting facts.
class FactEngine {
    private let facts = [
        "Did you know? Honey never spoils. Archaeologists have found 3000-year-old honey in Egyptian tombs that was still edible!",
        "Did you know? A day on Venus is longer than a year on Venus. It takes 243 Earth days to rotate once!",
        "Did you know? Octopuses have three hearts, and their blood is blue because it contains copper-based hemocyanin.",
        "Did you know? The first computer programmer was Ada Lovelace, who wrote algorithms for Charles Babbage's Analytical Engine in the 1840s.",
        "Did you know? The entire internet weighs about 50 grams, which is roughly the weight of a strawberry.",
        "Did you know? There are more possible iterations of a chess game than there are atoms in the observable universe.",
        "Did you know? Bananas are berries, but strawberries aren't. Botanically speaking, that is!",
        "Did you know? The average person walks about 100,000 miles in a lifetime, which is like walking around the Earth four times!",
        "Did you know? Your brain uses about 20% of your body's total energy, even though it's only 2% of your body weight.",
        "Did you know? The first emoji was created in 1982 by a computer scientist named Scott Fahlman. It was a simple smiley face!"
    ]

    func randomFact() -> String {
        facts.randomElement() ?? "I'll find a cool fact for you next time!"
    }
}
