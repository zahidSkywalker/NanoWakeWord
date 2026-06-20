//
//  WakeWordViewModel.swift
//  NanoWakeWord
//
//  Central ViewModel that bridges the wake word engine, voice assistant,
//  and UI. Follows the MVVM architecture pattern.
//

import Foundation
import Combine
import SwiftUI

/// Central view model managing the entire wake word + voice assistant flow.
class WakeWordViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var isProcessing: Bool = false
    @Published var statusMessage: String = "Tap to start"
    @Published var detectionCount: Int = 0
    @Published var lastCommand: String = ""
    @Published var lastResponse: String = ""
    @Published var currentStatus: AssistantDisplayState = .idle
    @Published var detectionHistory: [DetectionResult] = []
    @Published var showSettings: Bool = false
    @Published var showHistory: Bool = false
    @Published var showNotes: Bool = false
    @Published var showReminders: Bool = false
    @Published var errorMessage: String?
    @Published var waveAnimation: Bool = false

    /// Visual state for the main UI indicator.
    enum AssistantDisplayState: String {
        case idle = "Ready"
        case listening = "Listening..."
        case processing = "Thinking..."
        case speaking = "Speaking..."
        case detected = "Wake Word Detected!"
        case error = "Error"

        var pulseColor: Color {
            switch self {
            case .idle:       return Color.gray.opacity(0.6)
            case .listening:  return Color.blue
            case .processing: return Color.orange
            case .speaking:   return Color.green
            case .detected:   return Color.purple
            case .error:      return Color.red
            }
        }

        var icon: String {
            switch self {
            case .idle:       return "mic"
            case .listening:  return "waveform"
            case .processing: return "brain"
            case .speaking:   return "speaker.wave.2"
            case .detected:   return "checkmark.circle.fill"
            case .error:      return "exclamationmark.triangle"
            }
        }
    }

    // MARK: - Services

    private let wakeWordEngine: WakeWordEngine
    private let voiceAssistant: VoiceAssistant
    private let settings: AppSettings
    private let hapticManager: HapticManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.settings = .shared
        self.wakeWordEngine = WakeWordEngine()
        self.voiceAssistant = VoiceAssistant()
        self.hapticManager = HapticManager.shared

        // Bind voice assistant state
        voiceAssistant.$isSpeaking
            .receive(on: RunLoop.main)
            .sink { [weak self] speaking in
                self?.isSpeaking = speaking
                if speaking {
                    self?.currentStatus = .speaking
                    self?.waveAnimation = true
                }
            }
            .store(in: &cancellables)

        voiceAssistant.$currentStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .idle:
                    self.statusMessage = self.isListening ? "Listening for wake word..." : "Tap to start"
                    if self.currentStatus != .speaking {
                        self.currentStatus = .idle
                    }
                case .listening:
                    self.statusMessage = "Listening for your command..."
                    self.currentStatus = .listening
                    self.waveAnimation = true
                case .processing:
                    self.statusMessage = "Processing..."
                    self.currentStatus = .processing
                    self.isProcessing = true
                case .speaking:
                    self.statusMessage = "Speaking..."
                    self.currentStatus = .speaking
                }
            }
            .store(in: &cancellables)

        // Set up interaction callbacks
        voiceAssistant.onInteractionComplete = { [weak self] interaction in
            self?.handleInteractionComplete(interaction)
        }

        voiceAssistant.onError = { [weak self] error in
            self?.errorMessage = error.localizedDescription
            self?.currentStatus = .error
            self?.statusMessage = error.localizedDescription
        }

        // Load detection count
        self.detectionCount = UserDefaults.standard.integer(forKey: "detectionCount")
    }

    // MARK: - Public Actions

    /// Toggles the wake word engine on/off.
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    /// Starts the wake word detection engine.
    func startListening() {
        do {
            try wakeWordEngine.start { [weak self] keyword in
                self?.handleWakeWordDetection(keyword)
            }
            isListening = true
            statusMessage = "Listening for wake word..."
            currentStatus = .idle
            waveAnimation = false

            // Request speech permission while idle
            voiceAssistant.requestAuthorization()

            settings.isListening = true
            hapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            currentStatus = .error
            statusMessage = "Error: \(error.localizedDescription)"
            hapticManager.error()
        }
    }

    /// Stops the wake word detection engine.
    func stopListening() {
        wakeWordEngine.stop()
        isListening = false
        statusMessage = "Stopped"
        currentStatus = .idle
        waveAnimation = false
        settings.isListening = false
        voiceAssistant.stopSpeaking()
        voiceAssistant.stopListening()
        hapticManager.softTap()
    }

    /// Clears all detection history.
    func clearHistory() {
        detectionHistory.removeAll()
        detectionCount = 0
        UserDefaults.standard.set(0, forKey: "detectionCount")
    }

    /// Removes a specific detection from history.
    func removeDetection(at offsets: IndexSet) {
        detectionHistory.remove(atOffsets: offsets)
    }

    // MARK: - Private Handlers

    private func handleWakeWordDetection(_ keyword: String) {
        // Haptic + visual feedback
        hapticManager.wakeWordDetected()

        DispatchQueue.main.async {
            self.detectionCount += 1
            UserDefaults.standard.set(self.detectionCount, forKey: "detectionCount")
            self.currentStatus = .detected
            self.statusMessage = "Wake word detected! Listening..."

            // Auto-reset status after 2 seconds if no voice command starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.currentStatus == .detected {
                    self.currentStatus = .idle
                }
            }
        }

        // Start listening for a voice command
        voiceAssistant.startListeningForCommand()
    }

    private func handleInteractionComplete(_ interaction: VoiceInteraction) {
        DispatchQueue.main.async {
            let result = DetectionResult(
                wakeWord: "Hey Diana",
                timestamp: Date(),
                commandText: interaction.heardText,
                responseText: interaction.responseText,
                commandType: interaction.commandType,
                confidence: 1.0
            )

            self.detectionHistory.insert(result, at: 0)
            self.lastCommand = interaction.heardText
            self.lastResponse = interaction.responseText
            self.isProcessing = false
            self.waveAnimation = false

            // Keep only last 50 detections
            if self.detectionHistory.count > 50 {
                self.detectionHistory = Array(self.detectionHistory.prefix(50))
            }

            self.hapticManager.commandRecognized()
        }
    }
}
