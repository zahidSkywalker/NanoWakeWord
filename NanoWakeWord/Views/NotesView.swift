//
//  NotesView.swift
//  NanoWakeWord
//
//  Displays and manages user notes and reminders.
//

import SwiftUI

struct NotesView: View {
    @ObservedObject var viewModel: WakeWordViewModel
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Notes & Reminders")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Segment control
            Picker("View", selection: $selectedSegment) {
                Text("Notes").tag(0)
                Text("Reminders").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            if selectedSegment == 0 {
                notesSection
            } else {
                remindersSection
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Group {
            if AppSettings.shared.notes.isEmpty {
                emptyState(
                    icon: "note.text",
                    title: "No Notes Yet",
                    subtitle: "Say 'take a note' after the wake word to create notes."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(AppSettings.shared.notes) { note in
                            NoteCard(note: note)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90)
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        Group {
            if AppSettings.shared.reminders.isEmpty {
                emptyState(
                    icon: "bell",
                    title: "No Reminders",
                    subtitle: "Say 'remind me to...' after the wake word to set reminders."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(AppSettings.shared.reminders) { reminder in
                            ReminderCard(reminder: reminder)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90)
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Empty State

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))

            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: NoteItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 16))
                .foregroundColor(.yellow.opacity(0.7))

            VStack(alignment: .leading, spacing: 4) {
                Text(note.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))

                Text(note.createdAt, style: .relative)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }

            if note.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange.opacity(0.6))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Reminder Card

struct ReminderCard: View {
    let reminder: ReminderItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(reminder.isCompleted ? .green.opacity(0.7) : .red.opacity(0.6))

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .strikethrough(reminder.isCompleted, color: .white.opacity(0.3))

                Text(reminder.createdAt, style: .relative)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
