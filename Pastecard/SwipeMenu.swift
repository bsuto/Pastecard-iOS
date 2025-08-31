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
    let fColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: symbol)
                .font(Font.body.weight(.semibold))
                .frame(width:20)
            Text(label)
        }
        .foregroundStyle(fColor)
    }
}

struct SwipeMenu: View {
    @EnvironmentObject var card: Pastecard
    @ScaledMetric(relativeTo: .body) var textHeight: CGFloat = 24
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
                    menuCell(symbol: "arrow.clockwise", label: "Refresh", fColor: Color(networkMonitor.isConnected ? .primary : Color(UIColor.systemGray)))
                }
                .frame(height: textHeight)
                .disabled(!networkMonitor.isConnected)
                
                ShareLink (
                    item: shareText
                ) {
                    menuCell(symbol: "square.and.arrow.up", label: "Share", fColor: .primary)
                }
                .frame(height: textHeight)
                
                Button {
                    showSVC = true
                } label: {
                    menuCell(symbol: "questionmark.circle", label: "Help", fColor: .primary)
                }
                .frame(height: textHeight)
            }
            .headerProminence(.increased)
            
            Section(header: Text("pastecard.net/\(card.uid)")) {
                Button {
                    self.dismiss()
                    card.signOut()
                } label: {
                    menuCell(symbol: "rectangle.portrait.and.arrow.forward", label: "Sign Out", fColor: .primary)
                }
                .frame(height: textHeight)
                
                Button {
                    showDeleteAlert = true
                } label: {
                    menuCell(symbol: "trash", label: "Delete Account", fColor: Color(networkMonitor.isConnected ? .primary : Color(UIColor.systemGray)))
                }
                .frame(height: textHeight)
                .disabled(!networkMonitor.isConnected)
            }
        }
        .scrollDisabled(true)
        .presentationDetents([.medium, .fraction(0.67), .fraction(0.9)])
        .sheet(isPresented: $showSVC) {
            if networkMonitor.isConnected {
                SafariViewController(url: URL(string: "https://pastecard.net/help/#app")!)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button("Done") {
                            showSVC = false
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.bar)
                    .overlay(Rectangle().frame(width: nil, height: 1, alignment: .bottom).foregroundColor(Color(UIColor.systemFill)), alignment: .bottom)
                    HTMLView(fileName: "help", anchor: "app")
                }
            }
        }
        .alert("Are you sure?", isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                self.dismiss()
                Task {
                    do {
                        try await card.delete()
                    } catch { }
                }
            }
        }, message: {
            Text("Do you really want to delete your account? This cannot be undone.")
        })
    }
    
    private func refreshCard() {
        dismiss()
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
