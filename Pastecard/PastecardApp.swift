//
//  PastecardApp.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import SwiftUI

@main
struct PastecardApp: App {
    @StateObject var card = Pastecard()
    
    var body: some Scene {
        WindowGroup {
            if card.isSignedIn {
                CardView().environmentObject(card)
            } else {
                SignInView().environmentObject(card)
            }
        }
    }
}
