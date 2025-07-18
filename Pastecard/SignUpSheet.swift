//
//  SignUpSheet.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/15/23.
//

import SwiftUI
import PastecardCore

struct SignUpSheet: View {
    @EnvironmentObject var card: Pastecard
    @State private var newUser = ""
    @State private var invalidID = true
    @State private var errorMessage = ""
    @FocusState private var newFocus: Bool
    
    var body: some View {
        VStack {
            Text("Create a Pastecard")
                .padding(.top, 48)
                .font(.title3)
            HStack(spacing:0) {
                Text("pastecard.net/")
                TextField("ID", text: $newUser)
                    .background(Color(UIColor.systemBackground))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onChange(of: newUser) { _, newValue in
                        validate()
                    }
                    .onSubmit { Task { try await signUp() } }
                    .focused($newFocus)
                Spacer()
                Button {
                    Task { try await signUp() }
                } label: {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(invalidID ? Color(UIColor.placeholderText): Color(UIColor.link))
                }
                    .accessibilityLabel("Create account")
                    .disabled(invalidID)
            }
            .padding(12)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            Text(errorMessage)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .foregroundColor(.red)
            Spacer()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .frame(maxHeight: .infinity, alignment: .top)
        .edgesIgnoringSafeArea(.bottom)
        .presentationDetents([.fraction(0.33)])
        .onAppear{newFocus = true}
    }
    
    func signUp() async throws {
        if invalidID { return }
        
        let name = newUser.lowercased().trimmingCharacters(in: .whitespaces)
        let initialText = "Welcome to Pastecard for iPhone.\n\nSwipe up for an options menu, or tap this text to edit it and save your changes to the cloud.\n\nAccess your card from anywhere at pastecard.net/" + name
        let parameters: [String: String] = ["cardText": initialText, "createdFrom": "ios" ]
        let url = URL(string: "https://pastecard.net/api/users/" + name)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        let (_, response) = try await URLSession(configuration: .ephemeral).data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            if statusCode == 201 {
                try await card.signIn(name)
            } else if statusCode == 409 || statusCode == 403 {
                errorMessage = "Sorry, that ID is not available."
                throw NetworkError.signInError
            } else {
                errorMessage = "Oops, something didn’t work. Please try again."
                throw NetworkError.signInError
            }
        }
    }
    
    func validate() {
        let valid: Bool = newUser.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && !newUser.isEmpty && newUser.count < 21
        
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

struct SignUpSheet_Previews: PreviewProvider {
    static var previews: some View {
        SignUpSheet()
    }
}
