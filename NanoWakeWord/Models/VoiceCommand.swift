//
//  VoiceCommand.swift
//  NanoWakeWord
//
//  Parsed voice command ready for execution.
//

import Foundation

/// A voice command parsed from user speech input.
struct VoiceCommand {
    let rawText: String
    let type: CommandType
    let parameters: [String: String]

    /// The original speech text, lowercased and trimmed.
    var normalizedText: String {
        rawText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
