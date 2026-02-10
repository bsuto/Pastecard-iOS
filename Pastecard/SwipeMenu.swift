//
//  SwipeMenu.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI
import PastecardCore
import WebKit

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
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .foregroundStyle(networkMonitor.isConnected ? .primary : Color(UIColor.systemGray))
                .disabled(!networkMonitor.isConnected)
                
                ShareLink (
                    item: shareText
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .foregroundStyle(.primary)
                
                Button {
                    showSVC = true
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
            
            Section(header: Text("pastecard.net/\(card.uid)")) {
                Button {
                    self.dismiss()
                    card.signOut()
                } label: {
                    Label("Sign Out", systemImage: "arrow.right.to.line.square")
                }
                .foregroundStyle(.primary)
                
                Button {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
                .foregroundStyle(networkMonitor.isConnected ? .primary : Color(UIColor.systemGray))
                .disabled(!networkMonitor.isConnected)
            }
        }
        .scrollDisabled(true)
        .sheet(isPresented: $showSVC) {
            if networkMonitor.isConnected {
                SafariViewController(url: URL(string: "https://pastecard.net/help/#app")!)
                    .ignoresSafeArea()
            } else {
                if #available(iOS 26.0, *) {
                    ZStack {
                        WebView(
                            url: URL(string: "#app", relativeTo: Bundle.main.url(forResource: "help", withExtension: "html"))
                        )
                        VStack() {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    showSVC = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.primary)
                                        .font(.title)
                                        .padding()
                                }
                                .accessibilityLabel("Done")
                                .glassEffect()
                                .padding()
                            }
                        }
                    }
                }
                else {
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
                throw NetworkError.loadError
            }
        }
    }
}

struct SwipeMenu_Previews: PreviewProvider {
    static var previews: some View {
        SwipeMenu(shareText: "Example card text").environmentObject(Pastecard())
    }
}
