import SwiftUI

struct MacSettingsView: View {
    @EnvironmentObject var card: Pastecard
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showDeleteAlert = false
    @AppStorage("windowFloating") private var windowFloating = false
    @AppStorage("fontSize") private var fontSize: Double = 13
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !card.isSignedIn {
                SignInViewMac()
            } else if card.isLocal {
                generalControls
                
                GroupBox {
                    HStack {
                        Text("This Mac Only")
                        Spacer()
                        Button("Sign In or Sign Up") {
                            windowFloating = false
                            fontSize = 13
                            card.signOut()
                        }
                    }
                    .padding(4)
                } label: {
                    Text("Account")
                }
                
                helpLinks
            } else {
                generalControls
                
                GroupBox {
                    HStack() {
                        Button(action: {
                            if let url = URL(string: "https://pastecard.net/\(card.uid)") {
                                openURL(url)
                            }
                        }) {
                            Text("pastecard.net/")
                                .foregroundStyle(.secondary)
                            + Text(card.uid)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Sign Out") {
                            windowFloating = false
                            fontSize = 13
                            card.signOut()
                        }
                    }
                    .padding(4)
                } label: {
                    Text("Account")
                }
                
                helpLinks
            }
        }
        .padding()
        .frame(width: 380)
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await card.delete()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This cannot be undone.")
        }
        .animation(.easeInOut(duration: 0.25), value: card.isSignedIn)
        .animation(.easeInOut(duration: 0.25), value: card.isLocal)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
            guard let closingWindow = notification.object as? NSWindow,
                  closingWindow.identifier?.rawValue.hasPrefix(WindowIdentifier.settingsPrefix) == true
            else { return }
            
            guard !card.isSignedIn else { return }
            
            let otherWindows = NSApplication.shared.windows.filter {
                $0.identifier?.rawValue.hasPrefix(WindowIdentifier.mainPrefix) == true
            }
            
            if otherWindows.isEmpty {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    
    private var generalControls: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Floating Window")
                    Spacer()
                    Toggle("", isOn: $windowFloating)
                        .controlSize(.small)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                VStack(spacing: 4) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(fontSize))")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $fontSize, in: 10...24, step: 1)
                        .padding(.top, 4)
                }
            }
            .padding(4)
        } label: {
            Text("General")
        }
    }
    
    private var helpLinks: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Button("Help") {
                    HelpWindowController.shared.open(anchor: "basic")
                }
                .buttonStyle(.link)
                .font(.callout)
                .foregroundStyle(.primary)

                Button("Privacy & Terms") {
                    HelpWindowController.shared.open(anchor: "tos")
                }
                .buttonStyle(.link)
                .font(.callout)
                .foregroundStyle(.primary)
                
                if card.isSignedIn && !card.isLocal {
                    Button("Delete Account") {
                        showDeleteAlert = true
                    }
                    .buttonStyle(.link)
                    .font(.callout)
                    .disabled(!networkMonitor.isConnected)
                    .foregroundColor(.red)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Support")
        }
    }
}

struct MacSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MacSettingsView()
            .environmentObject(Pastecard())
    }
}
