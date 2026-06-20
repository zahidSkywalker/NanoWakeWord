# NanoWakeWord — Your Personal Offline Voice Assistant

A nano-sized, on-device wake word detector with a built-in voice assistant.
Runs entirely offline on your iPhone. No internet needed. No data sent to the cloud.

---

## Features

| Feature | Details |
|---------|---------|
| **Wake Word Detection** | Native Apple SFSpeechRecognizer — no external SDK needed |
| **Voice Commands** | Math, time, date, notes, reminders, jokes, facts, open apps, brightness |
| **Text-to-Speech** | Apple AVSpeechSynthesizer (built-in, zero size impact) |
| **Speech-to-Text** | Apple SFSpeechRecognizer (fully offline) |
| **Haptic Feedback** | Vibrations on wake word detection and command recognition |
| **Sound Effects** | Audio feedback on interactions |
| **Dark Mode UI** | Beautiful glassmorphism design with animated orb |
| **Multi-language** | Supports 10+ languages |
| **100% Private** | Everything runs on your device — zero cloud calls |
| **Customizable** | Adjust wake phrase, voice speed, personality, and more |

---

## Tech Stack

- **Language:** Swift 5
- **UI Framework:** SwiftUI
- **Wake Word Engine:** Native AVAudioEngine + SFSpeechRecognizer
- **STT:** Apple SFSpeechRecognizer (on-device)
- **TTS:** Apple AVSpeechSynthesizer (on-device)
- **Architecture:** MVVM (Model-View-ViewModel)
- **Minimum iOS:** 16.0
- **External Dependencies:** None

---

## Project Structure

```
NanoWakeWord/
├── codemagic.yaml                      ← Codemagic CI/CD (free macOS builds)
├── .github/workflows/build-ipa.yml     ← GitHub Actions (macOS runner)
├── README.md
│
└── NanoWakeWord/
    ├── App/
    │   └── NanoWakeWordApp.swift        ← App entry, permissions, auto-start
    │
    ├── Views/
    │   ├── ContentView.swift           ← Main tab-based navigation
    │   ├── HomeView.swift               ← Dashboard with animated orb
    │   ├── HistoryView.swift            ← Detection/command history
    │   ├── NotesView.swift               ← Notes & reminders manager
    │   └── SettingsView.swift           ← All configuration options
    │
    ├── ViewModels/
    │   └── WakeWordViewModel.swift      ← Central state management (MVVM)
    │
    ├── Services/
    │   ├── WakeWordEngine.swift          ← Native wake word detection engine
    │   ├── VoiceAssistant.swift          ← STT → Parse → TTS pipeline
    │   ├── CommandHandler.swift           ← Command parser + executor
    │   └── HapticManager.swift           ← Haptic + sound feedback
    │
    ├── Models/
    │   ├── DetectionResult.swift         ← Detection event model
    │   ├── VoiceCommand.swift            ← Parsed command model
    │   └── AppSettings.swift             ← Persistent settings + notes/reminders
    │
    └── Resources/
        └── Info.plist                    ← Permissions & configuration
```

---

## Build & Install

### Prerequisites

- **iPhone** running iOS 16 or later
- **Apple ID** (free is fine)

### Option 1: Build via Codemagic (Recommended — Free)

1. Go to [codemagic.io](https://codemagic.io) and sign up with GitHub
2. Add the `zahidSkywalker/NanoWakeWord` repository
3. Codemagic will auto-detect `codemagic.yaml` and build
4. Download the `.ipa` artifact when build completes

### Option 2: Build via GitHub Actions (Requires Paid GitHub Plan)

1. Go to repo **Actions** tab
2. Select "Build iOS IPA" workflow
3. Click **Run workflow**
4. Download `.ipa` from the Artifacts section

### Option 3: Build Locally (Requires Mac + Xcode)

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project NanoWakeWord.xcodeproj -scheme NanoWakeWord -sdk iphoneos CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO archive -archivePath build/NanoWakeWord.xcarchive
```

### Install on iPhone (No Mac Needed)

1. Get the `.ipa` file
2. Upload it to Google Drive, Dropbox, or any file hosting
3. Open **eSign** on your iPhone
4. Paste the download link
5. Sign with your Apple ID
6. Install!

> Free sideloaded apps refresh every **7 days**. Re-sign in eSign to extend.

---

## Voice Commands

| Command | Example | What It Does |
|---------|---------|-------------|
| Math | "Calculate 25 plus 37" | Solves math expressions |
| Time | "What time is it?" | Tells current time |
| Date | "What's today's date?" | Tells today's date |
| Note | "Take a note: buy groceries" | Saves a note locally |
| Reminder | "Remind me to call mom" | Creates a reminder |
| Joke | "Tell me a joke" | Tells a random joke |
| Fact | "Tell me a fact" | Shares a random fact |
| Timer | "Set a timer for 5 minutes" | Sets a timer |
| Open App | "Open Safari" | Opens system apps |
| Brightness | "Set brightness to high" | Adjusts screen brightness |
| General | "Hello", "Thank you", "Help" | Conversational responses |

---

## Privacy

- **No internet required** — everything runs on-device
- **No data collection** — zero analytics, zero tracking
- **No cloud APIs** — speech recognition and synthesis are 100% local
- **No external SDKs** — no Picovoice, no third-party tracking
- **App size** — under 5 MB (pure Apple frameworks)

---

## License

This project is for personal and educational use.