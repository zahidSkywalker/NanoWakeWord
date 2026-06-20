//
//  HistoryView.swift
//  NanoWakeWord
//
//  Displays detection and command history.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: WakeWordViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                if !viewModel.detectionHistory.isEmpty {
                    Button("Clear All") {
                        viewModel.clearHistory()
                        HapticManager.shared.softTap()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            if viewModel.detectionHistory.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))

            Text("No Detections Yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            Text("Start listening and use your wake word to see history here.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 80)
    }

    // MARK: - History List

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.detectionHistory) { detection in
                    DetectionCard(detection: detection)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)
        }
    }
}

// MARK: - Detection Card

struct DetectionCard: View {
    let detection: DetectionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: type + time
            HStack {
                if let type = detection.commandType {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.7))
                        Text(type.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
                }

                Spacer()

                Text(detection.formattedTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Command
            if let command = detection.commandText {
                HStack(alignment: .top, spacing: 8) {
                    Text("You:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue.opacity(0.7))
                    Text(command)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Response
            if let response = detection.responseText {
                HStack(alignment: .top, spacing: 8) {
                    Text("Diana:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green.opacity(0.7))
                    Text(response)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
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
