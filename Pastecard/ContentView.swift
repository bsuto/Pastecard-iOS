//
//  ContentView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/12/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var card = Pastecard()
    
    var body: some View {
        if !card.isSignedIn {
            SignInView()
                .environmentObject(card)
        } else {
            CardView()
                .environmentObject(card)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Pastecard())
    }
}
