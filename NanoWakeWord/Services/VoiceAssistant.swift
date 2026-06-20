//
//  VoiceAssistant.swift
//  NanoWakeWord
//
//  Orchestrates Speech-to-Text, command processing, and Text-to-Speech.
//  This is the main pipeline after wake word detection.
//

import Foundation
import AVFoundation
import Speech

/// Errors from voice assistant operations.
enum VoiceAssistantError: LocalizedError {
    case speechNotAuthorized
    case speechRecognizerError(String)
    case noSpeechDetected
    case audioEngineError(String)
    case ttsError(String)

    var errorDescription: String? {
        switch self {
        case .speechNotAuthorized:
            return "Speech recognition is not authorized. Enable it in Settings."
        case .speechRecognizerError(let detail):
            return "Speech recognizer error: \(detail)"
        case .noSpeechDetected:
            return "No speech was detected. Please try again."
        case .audioEngineError(let detail):
            return "Audio engine error: \(detail)"
        case .ttsError(let detail):
            return "Text-to-speech error: \(detail)"
        }
    }
}

/// Result of a voice interaction cycle.
struct VoiceInteraction {
    let heardText: String
    let commandType: CommandType
    let responseText: String
    let success: Bool
}

/// The main voice assistant that handles the full conversation pipeline:
/// Wake word → Listen → Parse → Respond (speak).
class VoiceAssistant: NSObject, ObservableObject {

    // MARK: - Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let commandHandler: CommandHandler
    private let settings: AppSettings

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isListeningForCommand = false

    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var lastHeardText: String = ""
    @Published var lastResponse: String = ""
    @Published var currentStatus: AssistantStatus = .idle

    enum AssistantStatus: String {
        case idle = "Idle"
        case listening = "Listening..."
        case processing = "Thinking..."
        case speaking = "Speaking..."
    }

    // MARK: - Callbacks

    var onInteractionComplete: ((VoiceInteraction) -> Void)?
    var onError: ((VoiceAssistantError) -> Void)?

    // MARK: - Initialization

    override init() {
        self.settings = .shared
        self.commandHandler = CommandHandler(settings: settings)
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: settings.language))
        super.init()

        speechSynthesizer.delegate = self
    }

    deinit {
        stopListening()
    }

    // MARK: - Speech Recognition Authorization

    /// Requests speech recognition permission. Call this at app launch.
    func requestAuthorization(completion: ((SFSpeechRecognizerAuthorizationStatus) -> Void)? = nil) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion?(status)
        }
    }

    // MARK: - Listen for Command

    /// Starts listening for a voice command after wake word detection.
    func startListeningForCommand() {
        guard !isListeningForCommand else { return }

        // Announce readiness, then start listening after speech finishes
        speakText(settings.personality.greeting) { [weak self] in
            self?.beginCapture()
        }
    }

    /// Starts capturing audio for speech recognition (internal).
    private func beginCapture() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError?(.audioEngineError(error.localizedDescription))
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            onError?(.speechNotAuthorized)
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = true  // Offline!

        let recognitionTask = speechRecognizer.recognitionTask(
            with: recognitionRequest!,
            resultHandler: { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.lastHeardText = text
                    }

                    if result.isFinal {
                        self.handleRecognizedText(text)
                    }
                }

                if error != nil {
                    self.stopListening()
                }
            }
        )
        self.recognitionTask = recognitionTask

        // Install audio tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListeningForCommand = true
            DispatchQueue.main.async {
                self.isListening = true
                self.currentStatus = .listening
            }
        } catch {
            onError?(.audioEngineError(error.localizedDescription))
        }
    }

    /// Stops listening and releases audio resources.
    func stopListening() {
        isListeningForCommand = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isListening = false
            self.currentStatus = .idle
        }
    }

    /// Processes recognized text and responds.
    private func handleRecognizedText(_ text: String) {
        DispatchQueue.main.async {
            self.currentStatus = .processing
        }
        stopListening()

        // Parse and execute command
        let command = commandHandler.parseCommand(from: text)
        let response = commandHandler.execute(command: command)

        // Save to detection history
        let interaction = VoiceInteraction(
            heardText: text,
            commandType: command.type,
            responseText: response,
            success: true
        )

        DispatchQueue.main.async {
            self.lastResponse = response
        }

        // Speak the response
        if settings.enableVoiceResponse {
            speakText(response) {
                self.onInteractionComplete?(interaction)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.onInteractionComplete?(interaction)
            }
        }
    }

    // MARK: - Text-to-Speech

    /// Speaks the given text aloud.
    /// - Parameters:
    ///   - text: The text to speak.
    ///   - completion: Optional callback when speaking finishes.
    func speakText(_ text: String, completion: (() -> Void)? = nil) {
        let utterance = AVSpeechUtterance(string: text)

        // Configure voice
        let locale = Locale(identifier: settings.language)
        let voice = AVSpeechSynthesisVoice.speechVoices().first { voice in
            voice.language == locale.identifier &&
            (settings.voiceGender == "female" ? voice.gender == .female : voice.gender == .male)
        } ?? AVSpeechSynthesisVoice(language: settings.language)

        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * settings.speakRate
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.9

        // Store completion handler
        self.pendingCompletion = completion

        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentStatus = .speaking
            self.speechSynthesizer.speak(utterance)
        }
    }

    /// Stops any ongoing speech.
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentStatus = .idle
    }

    // MARK: - Private

    private var pendingCompletion: (() -> Void)?
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceAssistant: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentStatus = .idle
        }
        pendingCompletion?()
        pendingCompletion = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentStatus = .speaking
        }
    }
}
