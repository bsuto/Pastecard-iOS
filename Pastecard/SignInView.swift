//
//  SignInView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var card: Pastecard
    
    @State private var userId = ""
    @State private var newUser = ""
    @State private var showSignUp = false
    @State private var showAlert = false
    @State private var showSVC = false
    @State private var validID = false
    @State private var signUpMessage = "Your Pastecard URL will be \n pastecard.net/(ID)"
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            HStack(alignment: .center) {
                Text("Pastecard")
                    .font(Font.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity)
            }.listRowBackground(Color.primary.opacity(0))
            Section(header: Text("Sign In")) {
                HStack(spacing:0) {
                    Text("pastecard.net/")
                    TextField("ID", text: $userId)
                        .onSubmit { signIn() }
                }
            }
            Section(header: Text("Create a Pastecard")) {
                Button {
                    showSignUp = true
                } label: {
                    Text("Sign Up")
                }
                Button {
                    showSVC = true
                } label: {
                    HStack {
                        Text("Privacy & Terms")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .alert("Choose a Pastecard ID", isPresented: $showSignUp) {
            TextField("ID", text: $newUser)
                .onChange(of: newUser) { newID in
                    let valid: Bool = newID.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && newID != "" && newID.count < 21
                    
                    // enable the submit button and update the helper text
                    if (valid) {
                        validID = true
                        signUpMessage = "Your Pastecard URL will be \n pastecard.net/\(newID)"
                    } else {
                        validID = false
                        if newID == "" {
                            signUpMessage = "Your Pastecard URL will be \n pastecard.net/(ID)"
                        } else if newID.count > 20 {
                            signUpMessage = "Invalid ID: \n 20 character maximum"
                        } else {
                            signUpMessage = "Invalid ID: \n Letters and numbers only"
                        }
                    }
                }
            Button("Submit", action: signUp)
                .disabled(!validID)
        } message: {
            Text(signUpMessage)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/#tos")!)
        }
    }
    
    func signIn() {
        // GET request
        let nameCheck = userId.lowercased()
        let url = URL(string: "https://pastecard.net/api/ios-check.php?user=" + (nameCheck.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        // send API request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {return}
            let responseString = String(data: data!, encoding: .utf8)
            
            // if user exists, log in with it
            if (responseString == "true") {
                card.signIn(nameCheck)
            } else {
                alertTitle = "😳"
                alertMessage = "The computer can’t find that username, sorry!"
                showAlert = true
            }
        }
        task.resume()
    }
    
    func signUp() {
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
                alertTitle = "😬"
                alertMessage = "That username is not available."
                showAlert = true
            } else {
                // if a server error
                alertTitle = "😳"
                alertMessage = "Oops, something didn't work. Please try again."
                showAlert = true
            }
        }
        task.resume()
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
