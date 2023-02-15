//
//  SignUpSheet.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/15/23.
//

import SwiftUI

struct SignUpSheet: View {
    @EnvironmentObject var card: Pastecard
    @State private var newUser = ""
    @State private var invalidID = true
    @State private var errorMessage = ""
    @FocusState private var newFocus: Bool
    
    var body: some View {
        VStack {
            Text("Create a Pastecard")
                .font(.headline)
            HStack(spacing:0) {
                Text("pastecard.net/")
                TextField("ID", text: $newUser)
                    .onChange(of: newUser) { newValue in
                        validate()
                    }
                    .onSubmit { signUp() }
                    .focused($newFocus)
                Spacer()
                Button {
                    signUp()
                } label: {
                    Image(systemName: "arrow.right.circle")
                }
                .accessibilityLabel("Create account")
                .disabled(invalidID)
            }
            .padding()
            Text(errorMessage)
                .foregroundColor(.red)
        }
        .presentationDetents([.fraction(0.25)])
        .onAppear{newFocus = true}
    }
    
    func signUp() {
        if (invalidID) { return }
        
        // GET request
        let name = newUser.lowercased()
        let url = URL(string: "https://pastecard.net/api/ios-signup.php?user=" + (name.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {return}
            let responseString = String(data: data!, encoding: .utf8)
            
            if (responseString == "success") {
                // if it succeeds, sign in with ID
                card.signIn(name)
            } else if (responseString == "taken") {
                // if the ID is taken
                errorMessage = "That username is not available."
            } else {
                // if a server error
                errorMessage = "Oops, something didn't work. Please try again."
            }
        }
        task.resume()
    }
    
    func validate() {
        let valid: Bool = newUser.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && !newUser.isEmpty && newUser.count < 21
        
        if (valid) {
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
