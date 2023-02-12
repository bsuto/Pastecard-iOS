//
//  ContentView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/12/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        if !user.isSignedIn {
            SignInView()
        } else {
            CardView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
