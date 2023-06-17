//
//  Shortcuts.swift
//  Pastecard
//
//  Created by Brian Sutorius on 6/13/23.
//

import AppIntents

struct IntentExtension: AppIntentsExtension {}

struct PastecardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetText(),
            phrases: ["What's on my \(.applicationName)", "Read me my \(.applicationName)"]
        )
        AppShortcut(
            intent: AppendText(),
            phrases: ["Add something to my \(.applicationName)"]
        )
    }
}
