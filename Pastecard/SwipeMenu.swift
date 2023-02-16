//
//  SwipeMenu.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI

struct SwipeMenu: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var card: Pastecard
    
    @State private var showSVC = false
    @State private var showDeleteAlert = false
    var shareText: String
    
    var body: some View {
        List {
            Section(header: Text("Pastecard").padding(.top, 24)) {
                Button {
                    self.dismiss()
                    Task {
                        await card.loadRemote()
                    }
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
                    showSVC = true
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(Font.body.weight(.semibold))
                        Text("Help")
                    }.foregroundColor(.primary)
                }
            }
            .headerProminence(.increased)
            Section(header: Text("pastecard.net/\(card.uid)")) {
                Button {
                    self.dismiss()
                    card.signOut()
                } label: {
                    HStack {
                        Image(systemName: "door.left.hand.open")
                            .font(Font.body.weight(.semibold))
                        Text("Sign Out")
                    }.foregroundColor(.primary)
                }
                Button {
                    showDeleteAlert = true
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
        .alert("Are you sure?", isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                self.dismiss()
                card.deleteAcct()
            }
        }, message: {
            Text("Do you really want to delete your account? This cannot be undone.")
        })
    }
}

struct SwipeMenu_Previews: PreviewProvider {
    static var previews: some View {
        SwipeMenu(shareText: "Example card text").environmentObject(Pastecard())
    }
}
