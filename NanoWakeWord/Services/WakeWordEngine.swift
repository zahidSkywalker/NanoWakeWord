//
//  WakeWordEngine.swift
//  NanoWakeWord
//
//  Core wake word detection engine using native AVAudioEngine.
//  Uses SFSpeechRecognizer for on-device speech recognition to detect
//  the wake word phrase. No external dependencies needed.
//

import Foundation
import AVFoundation
import Speech

/// Errors that can occur during wake word engine operations.
enum WakeWordError: LocalizedError {
    case microphonePermissionDenied
    case audioSessionError(String)
    case engineAlreadyRunning
    case engineNotRunning

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission was denied. Enable it in Settings > Privacy > Microphone."
        case .audioSessionError(let detail):
            return "Audio session error: \(detail)"
        case .engineAlreadyRunning:
            return "Wake word engine is already running."
        case .engineNotRunning:
            return "Wake word engine is not running."
        }
    }
}

/// Callback fired when the wake word is detected.
typealias WakeWordDetectionCallback = (_ keyword: String) -> Void

/// Manages wake word detection using native AVAudioEngine + SFSpeechRecognizer.
/// Approach: continuous speech recognition checks for wake word phrase in
/// partial/final transcription results. Fully offline, no API key needed.
class WakeWordEngine: NSObject {

    // MARK: - Properties

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    private var isRunning = false
    private var detectionCallback: WakeWordDetectionCallback?
    private let settings: AppSettings

    /// Cooldown to prevent rapid re-detection
    private var lastDetectionTime: Date = .distantPast
    private let detectionCooldown: TimeInterval = 3.0

    /// Whether the engine is currently active and listening.
    var listening: Bool { isRunning }

    // MARK: - Initialization

    override init() {
        self.settings = .shared
        super.init()
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: settings.language))
    }

    deinit {
        stop()
    }

    // MARK: - Public Methods

    /// Starts the wake word detection engine.
    /// - Parameter onDetection: Callback fired when wake word is detected.
    /// - Throws: `WakeWordError` if setup fails.
    func start(onDetection: @escaping WakeWordDetectionCallback) throws {
        guard !isRunning else {
            throw WakeWordError.engineAlreadyRunning
        }

        self.detectionCallback = onDetection

        // Request microphone permission
        let permissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch permissionStatus {
        case .authorized:
            break
        case .notDetermined:
            let semaphore = DispatchSemaphore(value: 0)
            var granted = false
            AVCaptureDevice.requestAccess(for: .audio) { g in
                granted = g
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 5)
            if !granted {
                throw WakeWordError.microphonePermissionDenied
            }
        case .denied, .restricted:
            throw WakeWordError.microphonePermissionDenied
        @unknown default:
            throw WakeWordError.microphonePermissionDenied
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            throw WakeWordError.audioSessionError(error.localizedDescription)
        }

        // Start continuous speech recognition to detect wake word
        startContinuousRecognition()

        isRunning = true
    }

    /// Stops the wake word detection engine and releases resources.
    func stop() {
        guard isRunning else { return }

        audioEngine?.stop()
        if let inputNode = audioEngine?.inputNode {
            inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore cleanup errors
        }

        isRunning = false
    }

    /// Restarts the engine with updated settings.
    func restart(onDetection: @escaping WakeWordDetectionCallback) throws {
        stop()
        try start(onDetection: onDetection)
    }

    // MARK: - Private Methods

    /// Starts continuous speech recognition to listen for the wake word.
    private func startContinuousRecognition() {
        let engine = AVAudioEngine()
        self.audioEngine = engine

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = true

        let task = speechRecognizer.recognitionTask(
            with: recognitionRequest!,
            resultHandler: { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    let text = result.bestTranscription.formattedString.lowercased()
                    let wakeWord = self.settings.wakeWord.lowercased()

                    // Check for wake word in partial or final results
                    if text.contains(wakeWord) {
                        let now = Date()
                        if now.timeIntervalSince(self.lastDetectionTime) >= self.detectionCooldown {
                            self.lastDetectionTime = now
                            self.detectionCallback?(self.settings.wakeWord)
                        }
                    }

                    // Reset recognition periodically to avoid timeout
                    if result.isFinal {
                        self.restartRecognition()
                    }
                }

                if let error = error {
                    let errorStr = error.localizedDescription.lowercased()
                    if !errorStr.contains("not authorized") &&
                       !errorStr.contains("cancelled") {
                        self.restartRecognition()
                    }
                }
            }
        )
        self.recognitionTask = task

        // Install audio tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            self.stop()
        }
    }

    /// Restarts speech recognition (used after final results or errors).
    private func restartRecognition() {
        guard isRunning else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, self.isRunning else { return }

            self.recognitionTask?.cancel()
            self.recognitionRequest?.endAudio()
            self.recognitionRequest = nil
            self.recognitionTask = nil

            if let inputNode = self.audioEngine?.inputNode {
                inputNode.removeTap(onBus: 0)
            }
            self.audioEngine?.stop()

            self.startContinuousRecognition()
        }
    }
}