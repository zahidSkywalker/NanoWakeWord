//
//  ContentView.swift
//  NanoWakeWord
//
//  Main entry view with tab-based navigation.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WakeWordViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.08, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab content
                TabView(selection: $selectedTab) {
                    HomeView(viewModel: viewModel)
                        .tag(0)

                    HistoryView(viewModel: viewModel)
                        .tag(1)

                    NotesView(viewModel: viewModel)
                        .tag(2)

                    SettingsView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)

                // Custom tab bar
                CustomTabBar(selectedTab: $selectedTab, viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @ObservedObject var viewModel: WakeWordViewModel

    private let tabs = [
        (icon: "house.fill", title: "Home", tag: 0),
        (icon: "clock.arrow.circlepath", title: "History", tag: 1),
        (icon: "note.text", title: "Notes", tag: 2),
        (icon: "gearshape.fill", title: "Settings", tag: 3),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                Button {
                    HapticManager.shared.softTap()
                    withAnimation {
                        selectedTab = tab.tag
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab.tag ? .white : .white.opacity(0.4))

                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == tab.tag ? .white : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .frame(height: 70)
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .top
        )
    }
}

// MARK: - Blur View Helper

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Preview

#Preview {
    ContentView()
}
