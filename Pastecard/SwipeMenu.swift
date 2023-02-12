//
//  SwipeMenu.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI

struct SwipeMenu: View {
    @Environment(\.dismiss) var dismiss
    @State private var showSVC = false
    @State private var showSignIn = false
    
    @State var online: Bool
    var uid: String
    var shareText: String
    
    var menuHeader: some View {
        if online {
            return AnyView( Text("Pastecard") )
        } else {
            return AnyView( HStack {
                Text("Pastecard")
                Spacer()
                Image(systemName: "xmark.icloud")
                    .font(Font.title2.weight(.semibold))
                    .foregroundColor(.red)
            } )
        }
    }
    
    var body: some View {
        List {
            Section(header: menuHeader.padding(.top, 24)) {
                Button {
                    online.toggle()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(Font.body.weight(.semibold))
                        Text("Refresh")
                    }.foregroundColor(.primary)
                }
                ShareLink (
                    item: shareText
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(Font.body.weight(.semibold))
                        Text("Share")
                    }.foregroundColor(.primary)
                }
                Button {
                    showSVC.toggle()
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(Font.body.weight(.semibold))
                        Text("Help")
                    }.foregroundColor(.primary)
                }
            }
            .headerProminence(.increased)
            Section(header: Text("pastecard.net/\(uid)")) {
                Button {
                    self.dismiss()
                    // user.signOut()
                } label: {
                    HStack {
                        Image(systemName: "door.right.hand.open")
                            .font(Font.body.weight(.semibold))
                        Text("Sign Out")
                    }.foregroundColor(.primary)
                }
                Button {
                    self.dismiss()
                    // user.deleteAcct()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .font(Font.body.weight(.semibold))
                        Text("Delete Account")
                    }.foregroundColor(.primary)
                }
            }
        }
        .presentationDetents([.medium])
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/")!)
        }
        .fullScreenCover(isPresented: $showSignIn) {
            SignInView()
        }
    }
}

struct SwipeMenu_Previews: PreviewProvider {
    static var previews: some View {
        SwipeMenu(online: true, uid: "example", shareText: "Card text")
    }
}
