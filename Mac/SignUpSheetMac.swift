#if os(macOS)

import SwiftUI

struct SignUpSheetMac: View {
    @EnvironmentObject var card: Pastecard
    @Environment(\.dismiss) var dismiss
    
    @State private var newUser = ""
    @State private var invalidID = true
    @State private var errorMessage = ""
    @State private var isCreating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create a Pastecard")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("pastecard.net/")
                        .foregroundColor(.secondary)
                    
                    TextField("ID", text: $newUser)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !invalidID {
                                Task { await signUp() }
                            }
                        }
                        .onChange(of: newUser) { _, _ in
                            validate()
                        }
                        .textCase(.lowercase)
                        .autocorrectionDisabled(true)
                }
                
                if errorMessage.isEmpty {
                    Text("Letters and numbers only, 20 characters max")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(".")
                
                Spacer()
                
                Button("Submit") {
                    Task { await signUp() }
                }
                .disabled(invalidID || isCreating)
                .keyboardShortcut(.return)
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 350, height: 200)
    }
    
    private func signUp() async {
        guard !invalidID else { return }
        
        isCreating = true
        let name = newUser.lowercased().trimmingCharacters(in: .whitespaces)
        let initialText = "Welcome to Pastecard.\n\nClick here to edit this text and save your changes to the cloud.\n\nAccess your card from anywhere at pastecard.net/" + name
        let parameters: [String: String] = ["cardText": initialText, "createdFrom": "macOS"]
        let url = URL(string: "https://pastecard.net/api/users/" + name)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await URLSession(configuration: .ephemeral).data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 201:
                    try await card.signIn(name)
                    dismiss()
                case 409, 403:
                    errorMessage = "Sorry, that ID is not available."
                default:
                    errorMessage = "Oops, something didn't work. Please try again."
                }
            }
        } catch {
            errorMessage = "Connection error. Please try again."
        }
        
        isCreating = false
    }
    
    private func validate() {
        let valid = newUser.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil 
                    && !newUser.isEmpty 
                    && newUser.count <= 20
        
        if valid {
            invalidID = false
            errorMessage = ""
        } else {
            invalidID = true
            if newUser.isEmpty {
                errorMessage = ""
            } else if newUser.count > 20 {
                errorMessage = "20 character maximum"
            } else {
                errorMessage = "Letters and numbers only"
            }
        }
    }
}

#endif
