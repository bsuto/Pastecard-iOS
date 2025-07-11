//
//  AppIntents.swift
//  Pastecard
//
//  Created by Brian Sutorius on 6/12/23.
//

import AppIntents
import PastecardCore

struct GetText: AppIntent {
    static var title: LocalizedStringResource = "Pastecard text"
    static var description =
    IntentDescription("Returns the text on your Pastecard.")
    static var openAppWhenRun = false
    
    private let core = PastecardCore.shared
    
    private func loadText() async throws -> String {
        if !core.isSignedIn {
            return "Please sign in first."
        }
        
        let localText = core.loadLocal()
        if !localText.isEmpty {
            return localText
        } else {
            // If local is empty, try to load from remote
            return try await core.loadRemote()
        }
    }
    
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let cardText = try await loadText()
        let dialog = IntentDialog(stringLiteral: cardText)
        return .result(value: cardText, dialog: dialog)
    }
}

struct AppendText: AppIntent {
    static var title: LocalizedStringResource = "Add to Pastecard"
    static var description =
    IntentDescription("Append some text to the end of your Pastecard.")
    static var openAppWhenRun = false
    
    @Parameter(title: "Text")
    var text: String?
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$text) to your Pastecard")
    }
    
    private let core = PastecardCore.shared
    
    private func append(_ newText: String) async throws -> String {
        if !core.isSignedIn {
            return "Please sign in first."
        }
        
        try await core.append(newText)
        return "Saved!"
    }
    
    func perform() async throws -> some ProvidesDialog {
        guard let text = text else {
            throw $text.needsValueError("What would you like to add to your Pastecard?")
        }
        
        let dialogMessage = try await append(text)
        let dialog = IntentDialog(stringLiteral: dialogMessage)
        return .result(dialog: dialog)
    }
}
