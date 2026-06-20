//
//  SettingsView.swift
//  NanoWakeWord
//
//  Configuration screen for wake word, sensitivity, voice, and appearance.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: WakeWordViewModel
    @ObservedObject private var settings = AppSettings.shared
    @State private var showAbout = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                Text("Settings")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)

                // Wake Word Section
                SettingsSection(title: "Wake Word") {
                    SettingsRow(icon: "mic.fill", title: "Wake Phrase") {
                        TextField("e.g., Hey Diana", text: $settings.wakeWord)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.trailing)
                    }

                    SettingsSliderRow(
                        icon: "waveform",
                        title: "Sensitivity",
                        value: $settings.sensitivity,
                        range: 0.0...1.0,
                        format: "%.2f"
                    )

                    SettingsToggleRow(
                        icon: "play.circle.fill",
                        title: "Auto-start on App Launch",
                        isOn: $settings.autoStartListening
                    )
                }

                // Voice Section
                SettingsSection(title: "Voice & Speech") {
                    SettingsToggleRow(
                        icon: "speaker.wave.2.fill",
                        title: "Voice Responses",
                        isOn: $settings.enableVoiceResponse
                    )

                    SettingsRow(icon: "person.fill", title: "Voice Gender") {
                        Picker("Gender", selection: $settings.voiceGender) {
                            Text("Female").tag("female")
                            Text("Male").tag("male")
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white.opacity(0.6))
                    }

                    SettingsSliderRow(
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        title: "Speech Speed",
                        value: $settings.speakRate,
                        range: 0.3...1.0,
                        format: "%.1fx"
                    )

                    SettingsRow(icon: "globe", title: "Language") {
                        Picker("Language", selection: $settings.language) {
                            Text("English (US)").tag("en-US")
                            Text("English (UK)").tag("en-GB")
                            Text("Spanish").tag("es-ES")
                            Text("French").tag("fr-FR")
                            Text("German").tag("de-DE")
                            Text("Arabic").tag("ar-SA")
                            Text("Bengali").tag("bn-BD")
                            Text("Hindi").tag("hi-IN")
                            Text("Japanese").tag("ja-JP")
                            Text("Chinese").tag("zh-CN")
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Feedback Section
                SettingsSection(title: "Feedback") {
                    SettingsToggleRow(
                        icon: "hand.tap.fill",
                        title: "Haptic Feedback",
                        isOn: $settings.enableHaptics
                    )

                    SettingsToggleRow(
                        icon: "speaker.fill",
                        title: "Sound Effects",
                        isOn: $settings.enableSound
                    )
                }

                // Appearance Section
                SettingsSection(title: "Appearance") {
                    SettingsToggleRow(
                        icon: "moon.fill",
                        title: "Dark Mode",
                        isOn: $settings.darkMode
                    )
                }

                // Personality Section
                SettingsSection(title: "Assistant Personality") {
                    SettingsRow(icon: "person.wave.2.fill", title: "Name") {
                        TextField("Diana", text: .constant(settings.personality.name))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.trailing)
                            .disabled(true)
                    }

                    SettingsRow(icon: "text.bubble.fill", title: "Greeting") {
                        TextField("Hey there!", text: .constant(settings.personality.greeting))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.trailing)
                            .disabled(true)
                    }
                }

                // About Section
                SettingsSection(title: "About") {
                    SettingsRow(icon: "info.circle.fill", title: "Version") {
                        Text("1.0.0")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    SettingsRow(icon: "keyboard", title: "Engine") {
                        Text("Apple Speech + TTS")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    SettingsRow(icon: "lock.shield.fill", title: "Privacy") {
                        Text("100% Offline")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green.opacity(0.7))
                    }
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(icon: icon, title: title) {
            Toggle("", isOn: $isOn)
                .tint(Color.blue)
                .labelsHidden()
        }
    }
}

// MARK: - Slider Row

struct SettingsSliderRow: View {
    let icon: String
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: String

    var body: some View {
        SettingsRow(icon: icon, title: title) {
            Text(String(format: format, value))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 40, alignment: .trailing)
        }

        Slider(value: $value, in: range)
            .tint(Color.blue)
            .padding(.horizontal, 50)
            .padding(.bottom, 4)
    }
}
