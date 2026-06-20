//
//  NanoWakeWordApp.swift
//  NanoWakeWord
//
//  Main app entry point.
//

import SwiftUI
import AVFoundation
import Speech
import UserNotifications

@main
struct NanoWakeWordApp: App {
    @StateObject private var viewModel = WakeWordViewModel()

    init() {
        // Configure appearance
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Request permissions on first launch
                    requestAllPermissions()

                    // Auto-start listening if enabled
                    if AppSettings.shared.autoStartListening {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            viewModel.startListening()
                        }
                    }
                }
        }
    }

    // MARK: - Setup

    private func setupAppearance() {
        // Global nav bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
    }

    private func requestAllPermissions() {
        // Microphone
        AVCaptureDevice.requestAccess(for: .audio) { _ in }

        // Speech Recognition
        SFSpeechRecognizer.requestAuthorization { _ in }

        // Notifications (for future reminder support)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
