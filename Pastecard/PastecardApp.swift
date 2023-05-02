//
//  PastecardApp.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import SwiftUI

@main
struct PastecardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var card = Pastecard()
    private let actionService = ActionService.shared
    
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
