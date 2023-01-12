//
//  SignInView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI

struct SignInView: View {
    @State var userId = ""
    
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    @State private var showSVC = false
    
    var body: some View {
        List {
            HStack(alignment: .center) {
                Text("Pastecard")
                    .font(Font.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity)
            }.listRowBackground(Color.primary.opacity(0))
            Section(header: Text("Sign in with your Pastecard ID")) {
                HStack(spacing:0) {
                    Text("pastecard.net/")
                    TextField("ID", text: $userId)
                        .focused($isFocused)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Spacer()
                            }
                            ToolbarItem(placement: .keyboard) {
                                Button("Sign In") {
                                    let signInValue = userId.lowercased()
                                    UserDefaults.standard.set(signInValue, forKey: "ID")
                                    dismiss()
                                }
                                .bold()
                            }
                        }
                }
            }
            Section(header: Text("Or, create a Pastecard")) {
                Button {
                    
                } label: {
                    Text("Sign Up")
                        .foregroundColor(.primary)
                }
            }
            Section {
                Button {
                    showSVC = true
                } label: {
                    HStack {
                        Text("Privacy & Terms")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .interactiveDismissDisabled(true)
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/#tos")!)
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(userId: "")
    }
}
