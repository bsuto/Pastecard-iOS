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
                .padding(.top, 24)
                .font(.title3)
            HStack(spacing:0) {
                Text("pastecard.net/")
                TextField("ID", text: $newUser)
                    .background(Color(UIColor.systemBackground))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onChange(of: newUser) { newValue in
                        validate()
                    }
                    .onSubmit { Task { await signUp() } }
                    .focused($newFocus)
                Spacer()
                Button {
                    Task { await signUp() }
                } label: {
                    Image(systemName: "arrow.right.circle")
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
        .presentationDetents([.fraction(0.2)])
        .onAppear{newFocus = true}
    }
    
    func signUp() async {
        if invalidID { return }
        
        let name = newUser.lowercased().trimmingCharacters(in: .whitespaces)
        let url = URL(string: "https://pastecard.net/api/ios-signup.php?user=" + (name.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let responseString = String(data: data, encoding: .utf8)
            if responseString == "success" {
                await card.signIn(name)
            } else if responseString == "taken" {
                errorMessage = "Sorry, that ID is not available."
            } else {
                errorMessage = "Oops, something didn’t work. Please try again."
            }
        } catch {
            errorMessage = "Oops, something didn’t work. Please try again."
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
