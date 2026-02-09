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
    private let refreshThreshold: TimeInterval = 60 // seconds
    
    init() {
        self.isSignedIn = core.isSignedIn
        if let savedUser = core.currentUser {
            self.uid = savedUser
            self.currentText = core.loadLocal()
        }
        if let lastRefreshTime = defaults.object(forKey: "lastRefresh") as? Date {
            self.lastRefreshed = lastRefreshTime
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
        defaults.removeObject(forKey: "lastRefresh")
        WidgetCenter.shared.reloadTimelines(ofKind: "PCWidget")
    }
    
    func refresh() async throws {
        guard isSignedIn else { return }
        
        loadingState = .loading
        do {
            let text = try await core.loadRemote()
            currentText = text
            loadingState = .loaded
            let now = Date()
            lastRefreshed = now
            defaults.set(now, forKey: "lastRefresh")
        } catch {
            currentText = core.loadLocal()
            loadingState = .error(error)
            throw NetworkError.loadError
        }
    }
    
    func refreshIfNeeded() async throws {
        let elapsed = Date().timeIntervalSince(lastRefreshed)
        guard elapsed > refreshThreshold else { return }

        try await refresh()
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
