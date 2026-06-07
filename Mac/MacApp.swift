//  macOS app entry point
#if os(macOS)

import SwiftUI
import PastecardCore

@main
struct PastecardMacApp: App {
    @StateObject private var card = Pastecard()
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    @AppStorage("windowFloating") private var windowFloating = false
    
    var body: some Scene {
        WindowGroup("Pastecard", id: "main") {
            if card.isSignedIn {
                MacCardView()
                    .environmentObject(card)
                    .onAppear {
                        applyWindowLevel(floating: windowFloating)
                    }
                    .onChange(of: windowFloating) { _, newValue in
                        applyWindowLevel(floating: newValue)
                    }
            } else {
                SignOutRedirectView()
                    .frame(width: 0, height: 0)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 250, height: 347)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .toolbar) {}
            CommandGroup(replacing: .sidebar) {}
            CommandGroup(replacing: .windowArrangement) {}
            CommandGroup(replacing: .windowSize) {}
            CommandMenu("Card") {
                Button("Refresh") {
                    Task { try? await card.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(card.loadingState == .loading || card.loadingState == .saving)
                
                Divider()
                
                Button("Share…") {
                    guard !card.currentText.isEmpty,
                          let window = NSApplication.shared.keyWindow,
                          let button = window.contentView
                    else { return }
                    let picker = NSSharingServicePicker(items: [card.currentText])
                    picker.show(relativeTo: .zero, of: button, preferredEdge: .minY)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(card.currentText.isEmpty)
                
                Button("Copy All Text") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(card.currentText, forType: .string)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(card.currentText.isEmpty)
            }
        }
        
        Settings {
            MacSettingsView()
                .environmentObject(card)
        }
    }
    
    private func applyWindowLevel(floating: Bool) {
        NSApplication.shared.windows.forEach { window in
            // Only apply to the main content window, not Settings or others
            guard window.identifier?.rawValue.hasPrefix("com_apple_SwiftUI_Settings") != true else { return }
            window.level = floating ? .floating : .normal
        }
    }
}

struct SignOutRedirectView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .onAppear {
                NSApplication.shared.keyWindow?.close()
                openSettings()
            }
    }
}


class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif

