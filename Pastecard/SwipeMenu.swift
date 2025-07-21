//
//  SwipeMenu.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI
import PastecardCore

struct menuCell: View {
    let symbol: String
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: symbol)
                .font(Font.body.weight(.semibold))
                .frame(width:20)
            Text(label)
        }.foregroundColor(.primary)
    }
}

struct SwipeMenu: View {
    @EnvironmentObject var card: Pastecard
    @Environment(\.dismiss) var dismiss
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var showSVC = false
    @State private var showDeleteAlert = false
    var shareText: String
    
    var body: some View {
        List {
            Section(header: Text("Pastecard").padding(.top, 24)) {
                Button {
                    refreshCard()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(Font.body.weight(.semibold))
                            .frame(width: 20)
                        Text("Refresh")
                    }
                    .foregroundColor(.primary)
                }
                
                ShareLink (
                    item: shareText
                ) {
                    menuCell(symbol: "square.and.arrow.up", label: "Share")
                }
                Button {
                    showSVC = true
                } label: {
                    menuCell(symbol: "questionmark.circle", label: "Help")
                }
            }
            .headerProminence(.increased)
            
            Section(header: Text("pastecard.net/\(card.uid)")) {
                Button {
                    self.dismiss()
                    card.signOut()
                } label: {
                    menuCell(symbol: "rectangle.portrait.and.arrow.forward", label: "Sign Out")
                    
                }
                Button {
                    showDeleteAlert = true
                } label: {
                    menuCell(symbol: "trash", label: "Delete Account")
                }
            }
        }
        .scrollDisabled(true)
        .presentationDetents([.medium, .fraction(0.67), .fraction(0.9)])
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/#app")!)
                .ignoresSafeArea()
        }
        .alert("Are you sure?", isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                self.dismiss()
                Task {
                    do { try await card.delete() }
                    catch { }
                }
            }
        }, message: {
            Text("Do you really want to delete your account? This cannot be undone.")
        })
    }
    
    private func refreshCard() {
        dismiss()
        guard networkMonitor.isConnected else { return }
        
        Task {
            do {
                try await card.refresh()
            } catch {
                throw NetworkError.signInError
            }
        }
    }
}

struct SwipeMenu_Previews: PreviewProvider {
    static var previews: some View {
        SwipeMenu(shareText: "Example card text").environmentObject(Pastecard())
    }
}
