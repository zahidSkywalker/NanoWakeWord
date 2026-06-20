//
//  HomeView.swift
//  NanoWakeWord
//
//  Main dashboard view with the prominent wake word status orb,
//  quick actions, and last interaction display.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: WakeWordViewModel
    @State private var orbPulse = false
    @State private var showCommandSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // Header
                headerSection

                // Main Orb
                mainOrbSection

                // Status Message
                statusSection

                // Quick Actions
                quickActionsSection

                // Last Interaction
                lastInteractionSection

                // Detection Counter
                statsSection

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NanoWakeWord")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(AppSettings.shared.personality.greeting)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Detection count badge
            VStack(spacing: 2) {
                Text("\(viewModel.detectionCount)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Detections")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 10)
    }

    // MARK: - Main Orb

    private var mainOrbSection: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        viewModel.currentStatus.pulseColor.opacity(
                            viewModel.isListening ? 0.15 - Double(ring) * 0.04 : 0.03
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: 200 + CGFloat(ring) * 30,
                        height: 200 + CGFloat(ring) * 30
                    )
                    .scaleEffect(orbPulse ? 1.05 : 1.0)
                    .animation(
                        viewModel.isListening
                            ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                            : .default,
                        value: orbPulse
                    )
            }

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            viewModel.currentStatus.pulseColor.opacity(0.3),
                            viewModel.currentStatus.pulseColor.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)

            // Main orb
            Button {
                HapticManager.shared.softTap()
                viewModel.toggleListening()
                orbPulse = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    viewModel.currentStatus.pulseColor.opacity(0.8),
                                    viewModel.currentStatus.pulseColor.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(
                            color: viewModel.currentStatus.pulseColor.opacity(0.5),
                            radius: viewModel.isListening ? 30 : 15,
                            x: 0,
                            y: 0
                        )

                    // Icon
                    Image(systemName: viewModel.currentStatus.icon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStatus)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 260)
        .padding(.top, 10)
        .onAppear { orbPulse = true }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.statusMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: viewModel.statusMessage)

            if viewModel.isListening {
                WaveformView(
                    isAnimating: viewModel.waveAnimation || viewModel.currentStatus == .listening
                )
                .frame(height: 30)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "mic.fill",
                    title: "Start Listening",
                    color: .blue,
                    isActive: viewModel.isListening
                ) {
                    viewModel.toggleListening()
                }

                QuickActionButton(
                    icon: "lightbulb.fill",
                    title: "Tell me a Fact",
                    color: .yellow
                ) {
                    showCommandSheet = true
                }

                QuickActionButton(
                    icon: "face.smiling.fill",
                    title: "Tell a Joke",
                    color: .green
                ) {
                    showCommandSheet = true
                }

                QuickActionButton(
                    icon: "clock.fill",
                    title: "What Time is it?",
                    color: .orange
                ) {
                    showCommandSheet = true
                }
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Last Interaction

    private var lastInteractionSection: some View {
        Group {
            if !viewModel.lastResponse.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last Response")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.3))

                        VStack(alignment: .leading, spacing: 4) {
                            if !viewModel.lastCommand.isEmpty {
                                Text(viewModel.lastCommand)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.4))
                            }

                            Text(viewModel.lastResponse)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(AppSettings.shared.notes.count)",
                label: "Notes",
                icon: "note.text",
                color: .yellow
            )

            StatCard(
                value: "\(AppSettings.shared.reminders.count)",
                label: "Reminders",
                icon: "bell",
                color: .red
            )

            StatCard(
                value: viewModel.isListening ? "ON" : "OFF",
                label: "Status",
                icon: "poweron",
                color: viewModel.isListening ? .green : .gray
            )
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isActive ? .white : color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isActive ? color : color.opacity(0.15))
                    )

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isActive ? 0.12 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isActive ? color.opacity(0.5) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let isAnimating: Bool

    @State private var offsets: [CGFloat] = Array(repeating: 0, count: 20)

    private let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 3, height: max(4, offsets[index]))
                    .animation(.easeInOut(duration: 0.2), value: offsets[index])
            }
        }
        .onReceive(timer) { _ in
            guard isAnimating else {
                offsets = Array(repeating: 0, count: 20)
                return
            }
            offsets = offsets.map { _ in
                CGFloat.random(in: 4...28)
            }
        }
    }
}
