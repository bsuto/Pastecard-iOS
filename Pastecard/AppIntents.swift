//
//  AppIntents.swift
//  Pastecard
//
//  Created by Brian Sutorius on 6/12/23.
//

import AppIntents

struct GetText: AppIntent {
    static var title: LocalizedStringResource = "Get contents of Pastecard"
    static var description =
    IntentDescription("Returns the contents of your Pastecard.")
    static var openAppWhenRun = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let defaults = UserDefaults(suiteName: "group.net.pastecard")!
        let user = defaults.string(forKey: "ID")
        
        if user == nil {
            return .result(value: "Please sign in first.")
        }
        
        var returnText = ""
        let randomInt = String(Int.random(in: 1...1000))
        let url = URL(string: "https://pastecard.net/api/db/" + user! + ".txt?" + randomInt)!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let remoteText = String(decoding: data, as: UTF8.self)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            if let localText = defaults.string(forKey: "text") {
                if !localText.isEmpty {
                    return .result(value: localText)
                } else {
                    returnText = localText
                }
            }
            throw NetworkError.loadError
        }
        
        if !remoteText.isEmpty { returnText = remoteText }
        return .result(value: returnText)
    }
}

struct AppendText: AppIntent {
    static var title: LocalizedStringResource = "Add to Pastecard"
    static var description =
    IntentDescription("Append the supplied text to the end of your Pastecard.")
    static var openAppWhenRun = false
    
    @Parameter(title: "Text")
    var text: String?
    
    func perform() async throws -> some ProvidesDialog {
        guard let providedText = text else {
            throw $text.needsValueError("What would you like to add to your Pastecard?")
        }
        
        let dialogMessage = try await append(providedText)
        let dialog = IntentDialog(stringLiteral: dialogMessage)
        return .result(dialog: dialog)
    }
    
    private func append(_ newText: String) async throws -> String {
        let uid = UserDefaults(suiteName: "group.net.pastecard")!.string(forKey: "ID")
        let sendText = newText.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        
        if uid == nil {
            return "Please sign in first."
        }
        else {
            let postData = ("user=" + uid! + "&text=" + sendText)
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
}
