//
//  Shortcuts.swift
//  Pastecard
//
//  Created by Brian Sutorius on 6/13/23.
//

import AppIntents

struct PastecardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetText(),
            phrases: ["What's on my \(.applicationName)", "Read me my \(.applicationName)", "Get the contents of my \(.applicationName)"]
        )
        AppShortcut(
            intent: AppendText(),
            phrases: ["Add something to my \(.applicationName)", "Append \(\.$text) to my \(.applicationName)"]
        )
    }
}
