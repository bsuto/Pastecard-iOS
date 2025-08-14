//
//  PastecardCore.swift
//  Pastecard
//
//  Created by Brian Sutorius on 7/2/25.
//

import Foundation
import WidgetKit

public enum NetworkError: Error, Sendable {
    case timeout
    case loadError
    case saveError
    case signInError
    case deleteAcctError
    case appendError
}

public enum LoadingState: Equatable, Sendable {
    case idle
    case loading
    case saving
    case loaded
    case error(Error)
    
    public static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.saving, .saving), (.loaded, .loaded):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

public struct PCJSON: Decodable {
    let username: String
    let cardText: String
    let lastUpdate: String
    let message: String?
}

public final class PastecardCore: @unchecked Sendable {
    public static let shared = PastecardCore()
    private let defaults = UserDefaults(suiteName: "group.net.pastecard")!
    private let session = URLSession(configuration: .ephemeral)
    private init() {}
    
    public var currentUser: String? {
        return defaults.string(forKey: "ID")
    }
    
    public var isSignedIn: Bool {
        return currentUser != nil
    }
    
    public func loadLocal() -> String {
        var returnText = ""
        if let localText = defaults.string(forKey: "text") {
            if !localText.isEmpty {
                returnText = localText
            }
        }
        return returnText
    }
    
    public func loadRemote() async throws -> String {
        guard let uid = currentUser else {
            throw NetworkError.signInError
        }
        
        var returnText = ""
        let url = URL(string: "https://pastecard.net/api/users/" + uid)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        let (data, response) = try await session.data(for: request)
        let remoteText = try! JSONDecoder().decode(PCJSON.self, from: data)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NetworkError.loadError
        }
        
        if !remoteText.cardText.isEmpty { returnText = remoteText.cardText }
        saveLocal(returnText)
        return returnText
    }
    
    public func saveLocal(_ text: String) {
        defaults.set(text, forKey: "text")
        WidgetCenter.shared.reloadTimelines(ofKind: "PCWidget")
    }
    
    public func saveRemote(_ text: String) async throws -> String {
        guard let uid = currentUser else {
            throw NetworkError.signInError
        }
        
        let parameters: [String: String] = ["text": text ]
        let url = URL(string: "https://pastecard.net/api/users/" + uid + "/write")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.saveError
        }
        
        let returnText = try! JSONDecoder().decode(PCJSON.self, from: data)
        saveLocal(returnText.cardText)
        return returnText.cardText
    }
    
    public func append(_ text: String) async throws {
        guard let uid = currentUser else {
            throw NetworkError.signInError
        }
        
        let parameters: [String: String] = ["text": text ]
        let url = URL(string: "https://pastecard.net/api/users/" + uid + "/append")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.appendError
        }
    }
    
    public func deleteAccount() async throws {
        guard let uid = currentUser else {
            throw NetworkError.signInError
        }
        
        let url = URL(string: "https://pastecard.net/api/users/" + uid + "/trash")!

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.deleteAcctError
        }
    }
}
