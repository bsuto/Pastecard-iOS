//
//  Pastecard.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/12/23.
//

import WidgetKit
import PastecardCore

@MainActor class Pastecard: ObservableObject {
    @Published var isSignedIn: Bool
    @Published var uid = ""
    @Published var currentText = ""
    @Published var loadingState: LoadingState = .idle
    @Published var lastRefreshed = Date.distantPast
    
    private let core = PastecardCore.shared
    private let defaults = UserDefaults(suiteName: "group.net.pastecard")!
    
    init() {
        self.isSignedIn = core.isSignedIn
        if let savedUser = core.currentUser {
            self.uid = savedUser
            self.currentText = core.loadLocal()
        }
    }
    
    func signIn(_ user: String) async throws {
        self.isSignedIn = true
        self.uid = user
        defaults.set(user, forKey: "ID")
        
        do {
            try await refresh()
        } catch {
            throw NetworkError.signInError
        }
    }
    
    func signOut() {
        self.isSignedIn = false
        self.uid = ""
        self.currentText = ""
        self.loadingState = .idle
        defaults.removeObject(forKey: "ID")
        defaults.removeObject(forKey: "text")
        WidgetCenter.shared.reloadTimelines(ofKind: "PCWidget")
    }
    
    func refresh() async throws {
        guard isSignedIn else { return }
        
        loadingState = .loading
        do {
            let text = try await core.loadRemote()
            currentText = text
            loadingState = .loaded
        } catch {
            currentText = core.loadLocal()
            loadingState = .error(error)
            throw NetworkError.loadError
        }
    }
    
    func save(_ text: String) async throws {
        guard isSignedIn else { return }
        
        loadingState = .saving
        do {
            let savedText = try await core.saveRemote(text)
            currentText = savedText
            loadingState = .loaded
        } catch {
            loadingState = .error(error)
            throw NetworkError.saveError
        }
    }
    
    func delete() async throws {
        try await core.deleteAccount()
        self.signOut()
    }
}
