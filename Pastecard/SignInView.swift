//
//  SignInView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import Combine
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var card: Pastecard
    @State private var userId = ""
    @State private var showSignUp = false
    @State private var showSVC = false
    @State private var errorMessage = ""
    @FocusState private var idFocus: Bool
    
    var body: some View {
        GeometryReader { geo in
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
                            .focused($idFocus)
                            .onSubmit { signIn() }
                        Spacer()
                        Button {
                            idFocus = false
                            signIn()
                        } label: {
                            Image(systemName: "arrow.right.circle")
                        }
                        .accessibilityLabel("Sign in with \(userId)")
                        .disabled(userId.isEmpty)
                    }
                }
                Section(){
                    Text(errorMessage)
                        .padding(.top, -18)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.primary.opacity(0))
                }
                Section(header: Text("Create a Pastecard")) {
                    Button {
                        idFocus = false
                        showSignUp = true
                    } label: {
                        Text("Sign Up")
                    }
                    Button {
                        idFocus = false
                        showSVC = true
                    } label: {
                        HStack {
                            Text("Privacy & Terms")
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                Color("TrademarkBlue")
                    .frame(width: geo.size.width,
                           height: geo.safeAreaInsets.top)
                    .padding(.top, -geo.safeAreaInsets.top)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpSheet()
        }
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/#tos")!)
        }
    }
    
    func signIn() {
        if userId.isEmpty { return }
        
        // GET request
        let nameCheck = userId.lowercased()
        let url = URL(string: "https://pastecard.net/api/ios-signin.php?user=" + (nameCheck.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
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
                errorMessage = "The computer can’t find that ID, sorry!"
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
