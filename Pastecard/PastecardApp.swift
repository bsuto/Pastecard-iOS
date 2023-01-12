//
//  PastecardApp.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import SwiftUI

@main
struct PastecardApp: App {
    let userId = UserDefaults.standard.string(forKey: "ID") ?? ""
    
    var body: some Scene {
        WindowGroup {
            if userId.isEmpty {
                SignInView()
            } else {
                ContentView()
            }
        }
    }
}
