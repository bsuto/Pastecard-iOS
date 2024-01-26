//
//  AppIntents.swift
//  Pastecard
//
//  Created by Brian Sutorius on 6/12/23.
//

import AppIntents

struct GetText: AppIntent {
    static var title: LocalizedStringResource = "Pastecard text"
    static var description =
    IntentDescription("Returns the text on your Pastecard.")
    static var openAppWhenRun = false
    
    private func loadText() async throws -> String {
        let defaults = UserDefaults(suiteName: "group.net.pastecard")!
        let user = defaults.string(forKey: "ID")
        var returnText = ""
        
        if user == nil {
            return "Please sign in first."
        }
        else if let localText = defaults.string(forKey: "text") {
            if !localText.isEmpty {
                returnText = localText
            } else {
                let randomInt = String(Int.random(in: 1...1000))
                let url = URL(string: "https://pastecard.net/api/db/" + user! + ".txt?" + randomInt)!
                let (data, response) = try await URLSession.shared.data(from: url)
                let remoteText = String(decoding: data, as: UTF8.self)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw NetworkError.loadError }
                if !remoteText.isEmpty { returnText = remoteText }
            }
        }
        
        return returnText
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
    
    private func append(_ newText: String) async throws -> String {
        let user = UserDefaults(suiteName: "group.net.pastecard")!.string(forKey: "ID")
        let sendText = newText.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        
        if user == nil {
            return "Please sign in first."
        }
        else {
            let postData = ("user=" + user! + "&text=" + sendText)
            let url = URL(string: "https://pastecard.net/api/ios-append.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = postData.data(using: String.Encoding.utf8)
            request.timeoutInterval = 5.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NetworkError.appendError
            }
            
            return "Saved!"
        }
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
