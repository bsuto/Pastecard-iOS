//
//  PastecardApp.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import SwiftUI
import TipKit

@main
struct PastecardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var card = Pastecard()
    private let actionService = ActionService.shared
    
    init() {
        if UserDefaults.standard.bool(forKey: "resetTip") {
            try? Tips.resetDatastore()
            UserDefaults.standard.set(false, forKey: "resetTip")
        }
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if card.isSignedIn {
                    CardView()
                        .environmentObject(card)
                        .environmentObject(actionService)
                } else {
                    SignInView()
                        .environmentObject(card)
                        .environmentObject(actionService)
                }
            }
            .animation(.default, value: card.isSignedIn)
        }
    }
}

struct SwipeTip: Tip {
    @Parameter
    static var clearedCard: Bool = false
    
    var title: Text { Text("Show the App Menu") }
    var message: Text? { Text("Swipe up on the middle of the screen for the app menu.") }
    var image: Image? { Image(systemName: "hand.draw") }
    var rules: [Rule] { #Rule(Self.$clearedCard) { $0 == true } }
}
