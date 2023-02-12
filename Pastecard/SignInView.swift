//
//  SignInView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var user: User
    
    @State private var showSVC = false
    @State private var userId = ""
    
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
                    signUp()
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
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/#tos")!)
        }
    }
    
    func signIn() {
        user.signIn(userId)
    }
    func signUp() {
        user.signIn(userId)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
