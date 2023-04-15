//
//  Pastecard.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/12/23.
//

import Foundation
import WidgetKit

enum NetworkError: Error {
    case timeout
    case loadError
    case saveError
    case appendError
    case signInError
    case deleteAcctError
}

@MainActor class Pastecard: ObservableObject {
    @Published var isSignedIn: Bool
    @Published var uid = ""
    @Published var refreshCalled = false
    let defaults = UserDefaults(suiteName: "group.net.pastecard")!
    
    init() {
        if let savedUser = defaults.string(forKey: "ID") {
            self.isSignedIn = true
            self.uid = savedUser
        } else {
            self.isSignedIn = false
        }
    }
    
    func signIn(_ user: String) async {
        self.isSignedIn = true
        self.uid = user
        defaults.set(user, forKey: "ID")
    }
    
    func signOut() {
        self.isSignedIn = false
        self.uid = ""
        defaults.set(nil, forKey: "ID")
        defaults.set(nil, forKey: "text")
        WidgetCenter.shared.reloadTimelines(ofKind: "PCWidget")
    }
    
    func deleteAcct() async throws {
        let url = URL(string: "https://pastecard.net/api/ios-deleteacct.php?user=" + (self.uid.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
        let (data, response) = try await URLSession.shared.data(from: url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NetworkError.deleteAcctError
        }
        let responseString = String(decoding: data, as: UTF8.self)
        if responseString == "success" {
            self.signOut()
        } else {
            throw NetworkError.deleteAcctError
        }
    }
    
    func loadLocal() -> String {
        var returnText = ""
        if let localText = defaults.string( forKey: "text") {
            if !localText.isEmpty {
                returnText = localText
            }
        }
        return returnText
    }

    func loadRemote() async throws -> String {
        var returnText = ""
        let url = URL(string: "https://pastecard.net/api/db/" + self.uid + ".txt")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        let remoteText = String(decoding: data, as: UTF8.self)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NetworkError.loadError
        }
        
        if !remoteText.isEmpty {
            returnText = remoteText
        }
        
        self.saveLocal(returnText)
        return returnText
    }
    
    func saveLocal(_ text: String) {
        defaults.set(text, forKey: "text")
        WidgetCenter.shared.reloadTimelines(ofKind: "PCWidget")
    }
    
    func saveRemote(_ text: String) async throws -> String {
        let sendText = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let postData = ("user=" + self.uid + "&text=" + sendText)
        let url = URL(string: "https://pastecard.net/api/ios-write.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: String.Encoding.utf8)
        request.timeoutInterval = 10.0
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.saveError
        }
        
        let returnText = String(decoding: data, as: UTF8.self).removingPercentEncoding
        self.saveLocal(returnText!)
        return returnText!
    }
    
    func append(_ text: String) async throws {
        let sendText = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let postData = ("user=" + self.uid + "&text=" + sendText)
        let url = URL(string: "https://pastecard.net/api/ios-append.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: String.Encoding.utf8)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.appendError
        }
    }
}
