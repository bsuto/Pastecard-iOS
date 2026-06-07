#if os(macOS)

import SwiftUI
import PastecardCore

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
            } else {
                generalControls
                
                GroupBox {
                        HStack {
                            Text(card.uid)
                                .textSelection(.enabled)
                            
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
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Help") {
                            NSHelpManager.shared.openHelpAnchor("app", inBook: "net.pastecard.Pastecard.help")
                        }
                        .buttonStyle(.link)
                        .font(.callout)
                        .foregroundStyle(.primary)
    
                        Button("Privacy & Terms") {
                            NSHelpManager.shared.openHelpAnchor("tos", inBook: "net.pastecard.Pastecard.help")
                        }
                        .buttonStyle(.link)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        
                        Button("Delete Account") {
                            showDeleteAlert = true
                        }
                        .buttonStyle(.link)
                        .font(.callout)
                        .disabled(!networkMonitor.isConnected)
                        .foregroundColor(.red)
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("Support")
                }
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
                  closingWindow.identifier?.rawValue.hasPrefix("com_apple_SwiftUI_Settings") == true
            else { return }
            
            let otherWindows = NSApplication.shared.windows.filter {
                $0.identifier?.rawValue.hasPrefix("main-AppWindow") == true
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
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                VStack(spacing: 4) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(fontSize))pt")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $fontSize, in: 10...24, step: 1)
                }
            }
            .padding(4)
        } label: {
            Text("General")
        }
    }
}

struct MacSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MacSettingsView()
            .environmentObject(Pastecard())
    }
}

#endif
