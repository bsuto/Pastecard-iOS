//
//  Pastecard.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/12/23.
//

import UIKit
import WidgetKit
import PastecardCore

@MainActor class Pastecard: ObservableObject {
    @Published var isSignedIn: Bool
    var isLocal: Bool { return core.isLocal }
    @Published var uid = ""
    @Published var currentText = ""
    @Published var loadingState: LoadingState = .idle
    @Published var lastRefreshed = Date.distantPast
    
    private let core = PastecardCore.shared
    private let defaults = UserDefaults(suiteName: "group.net.pastecard")!
    private let refreshThreshold: TimeInterval = 60 // seconds
    
    init() {
        if core.isSignedIn {
            self.isSignedIn = true
            self.uid = core.currentUser!
            self.currentText = core.loadLocal()
        } else if !core.firstRunDone {
            defaults.set(PastecardCore.localUser, forKey: "ID")
            self.isSignedIn = true
            self.uid = PastecardCore.localUser
            core.loadLocalsOnly()
            self.currentText = core.loadLocal()
            core.setFirstRunDone()
        } else {
            self.isSignedIn = false
        }
        
//        self.isSignedIn = core.isSignedIn
//        if let savedUser = core.currentUser {
//            self.uid = savedUser
//            self.currentText = core.loadLocal()
//        } else {
//            defaults.set(PastecardCore.localUser, forKey: "ID")
//            self.isSignedIn = true
//            self.uid = PastecardCore.localUser
//            self.currentText = ""
//        }
    }
    
    func signIn(_ user: String) async throws {
        self.isSignedIn = true
        self.uid = user
        defaults.set(user, forKey: "ID")
        
        if core.isLocal {
            core.loadLocalsOnly()
            self.currentText = core.loadLocal()
            self.loadingState = .loaded
            return
        }
        
        do {
            try await refresh()
        } catch {
            throw NetworkError.signInError
        }
    }
    
    func signOut() {
        if isLocal && !currentText.isEmpty {
            UIPasteboard.general.string = currentText
        }
        
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
        guard !isLocal else {
            currentText = core.loadLocal()
            loadingState = .loaded
            return
        }
        
        await MainActor.run { loadingState = .loading }
        do {
            let text = try await core.loadRemote()
            await MainActor.run {
                currentText = text
                loadingState = .loaded
                lastRefreshed = Date()
            }
        } catch {
            await MainActor.run {
                currentText = core.loadLocal()
                loadingState = .error(error)
            }
            throw NetworkError.loadError
        }
    }

    func checkRefresh() async throws {
        guard loadingState != .loading && loadingState != .saving else { return }
        
        let elapsed = Date().timeIntervalSince(lastRefreshed)
        if lastRefreshed == Date.distantPast || elapsed > refreshThreshold {
            try? await refresh()
        }
    }
    
    func save(_ text: String) async throws {
        guard isSignedIn else { return }
        if isLocal {
            core.saveLocal(text)
            currentText = text
            loadingState = .loaded
            return
        }
        
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
