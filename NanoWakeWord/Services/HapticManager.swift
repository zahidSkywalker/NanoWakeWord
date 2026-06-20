//
//  HapticManager.swift
//  NanoWakeWord
//
//  Manages haptic feedback for wake word detection and interactions.
//

import Foundation
import AudioToolbox
import UIKit

/// Provides haptic and sound feedback for app events.
class HapticManager {

    static let shared = HapticManager()
    private let settings: AppSettings

    private init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    /// Plays a subtle impact when wake word is detected.
    func wakeWordDetected() {
        guard settings.enableHaptics else { return }

        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()

            // Play a subtle detection sound
            if self.settings.enableSound {
                SystemSound.play(SystemSound.keyPress)
            }
        }
    }

    /// Plays a light tap when command is recognized.
    func commandRecognized() {
        guard settings.enableHaptics else { return }

        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    /// Plays a success notification.
    func success() {
        guard settings.enableHaptics else { return }

        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    /// Plays an error vibration pattern.
    func error() {
        guard settings.enableHaptics else { return }

        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    /// Plays a soft tap for UI interactions.
    func softTap() {
        guard settings.enableHaptics else { return }

        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// MARK: - System Sound Helper

enum SystemSound {
    static func play(_ sound: SystemSoundID) {
        AudioServicesPlaySystemSound(sound)
    }

    static let keyPress: SystemSoundID = 1104
    static let tweet: SystemSoundID = 1016
    static let notification: SystemSoundID = 1007
}
