//
//  AppIntents.swift
//  Pastecard
//
//  Created by Brian Sutorius on 6/12/23.
//

import AppIntents
import PastecardCore

struct GetText: AppIntent {
    static var title: LocalizedStringResource = "Get Pastecard text"
    static var description = IntentDescription("Returns the text on your Pastecard.")
    static var openAppWhenRun = false
    
    private let core = PastecardCore.shared
    
    private func loadText() async throws -> String {
        let localText = core.loadLocal()
        if !localText.isEmpty {
            return localText
        } else {
            // If local is empty, try to load from remote just in case
            return try await core.loadRemote()
        }
    }
    
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
            if !core.isSignedIn {
                let dialog = IntentDialog("Please open the app and sign in first.")
                return .result(value: "", dialog: dialog)
            }
            
            let cardText = try await loadText()
            let dialog: IntentDialog
            if cardText.isEmpty {
                dialog = "Your Pastecard is empty."
            } else {
                dialog = IntentDialog(stringLiteral: cardText)
            }
            
            return .result(value: cardText, dialog: dialog)
        }
}

struct AppendText: AppIntent {
    static var title: LocalizedStringResource = "Add to Pastecard"
    static var description = IntentDescription("Append some text to the end of your Pastecard.")
    static var openAppWhenRun = false
    
    @Parameter(title: "Text", requestValueDialog: IntentDialog("What would you like to add?"))
    var text: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$text) to your Pastecard")
    }
    
    private let core = PastecardCore.shared

    func perform() async throws -> some ProvidesDialog {
        if !core.isSignedIn {
            return .result(dialog: "Please open the app and sign in first.")
        }
        
        try await core.append(text)
        return .result(dialog: "")
    }
}

struct ShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor {
        return .navy
    }
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetText(),
            phrases: ["What's on my \(.applicationName)", "Read me my \(.applicationName)", "Get \(.applicationName)"],
            shortTitle: "Get Text",
            systemImageName: "inset.filled.topthird.square"
        )
        AppShortcut(
            intent: AppendText(),
            phrases: ["Add something to my \(.applicationName)", "Add to \(.applicationName)"],
            shortTitle: "Add Text",
            systemImageName: "plus.square"
        )
    }
}

struct IntentExtension: AppIntentsExtension {}
