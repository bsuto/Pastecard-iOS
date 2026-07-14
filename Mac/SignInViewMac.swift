import SwiftUI
internal import Combine

struct SignInViewMac: View {
    @EnvironmentObject var card: Pastecard
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var userId = ""
    @State private var showSignUp = false
    @State private var errorMessage = ""
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: 24) {
            GroupBox {
                HStack(spacing: 0) {
                    Text("pastecard.net/")
                        .foregroundColor(.secondary)
                    
                    TextField(
                        text: $userId,
                        prompt: Text("ID")
                    ) {
                        EmptyView()
                    }
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !userId.isEmpty && networkMonitor.isConnected {
                            Task { await signIn() }
                        }
                    }
                    // .textCase(.lowercase)
                    .frame(minWidth: 150, maxWidth: 300, alignment: .leading)
                    .autocorrectionDisabled(true)
                    .onReceive(Just(userId)) { _ in charLimit(20) }
                    
                    Spacer()
                    
                    Button("Go") {
                        Task { await signIn() }
                    }
                    // .keyboardShortcut(.return)
                    .disabled(userId.isEmpty || !networkMonitor.isConnected || isSigningIn)
                    .buttonStyle(.bordered)
                }
                .padding(4)
            } label: {
                Text("Sign In")
            }
            
            if errorMessage.isEmpty {
                Text("")
            } else {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Button("Create a Pastecard") {
                    showSignUp = true
                }
                .buttonStyle(.link)
                .foregroundStyle(.primary)
                .disabled(!networkMonitor.isConnected)
                
                Button("Use Without an Account") {
                    Task {
                        try? await card.signIn(PastecardCore.localUser)
                        WindowManager.resetToMainWindow(openWindow: openWindow)
                    }
                }
                .buttonStyle(.link)
                .foregroundStyle(.primary)
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Sign Up")
        }
        
        HStack() {
            Button("Help") {
                HelpWindowController.shared.open(anchor: "app")
            }
            .buttonStyle(.link)
            .font(.callout)
            .foregroundStyle(.primary)
            
            Spacer()
            
            Button("Privacy & Terms") {
                HelpWindowController.shared.open(anchor: "tos")
            }
            .buttonStyle(.link)
            .font(.callout)
            .foregroundStyle(.primary)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        
        
        .sheet(isPresented: $showSignUp) {
            SignUpSheetMac()
                .environmentObject(card)
        }
    }
    
    private func charLimit(_ upper: Int) {
        if userId.count > upper {
            userId = String(userId.prefix(upper))
        }
    }
    
    private func signIn() async {
        guard !userId.isEmpty && networkMonitor.isConnected else { return }
        
        isSigningIn = true
        errorMessage = ""
        
        let nameCheck = userId.lowercased().trimmingCharacters(in: .whitespaces)
        let url = URL(string: "https://pastecard.net/api/users/" + nameCheck)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await URLSession(configuration: .ephemeral).data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    try await card.signIn(nameCheck)
                    errorMessage = ""
                    WindowManager.resetToMainWindow(openWindow: openWindow)
                case 404:
                    errorMessage = "Sorry, the computer can't find that ID."
                default:
                    errorMessage = "Oops, something didn't work. Please try again."
                }
            }
        } catch {
            print("Error type: \(type(of: error))")
                print("Error: \(error)")
                print("Localized: \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    print("URLError code: \(urlError.code)")
                    print("URLError code raw: \(urlError.code.rawValue)")
                }
            errorMessage = "Connection error. Please check your internet and try again."
        }
        
        isSigningIn = false
    }
}

struct SignInViewMac_Previews: PreviewProvider {
    static var previews: some View {
        SignInViewMac()
            .environmentObject(Pastecard())
    }
}
