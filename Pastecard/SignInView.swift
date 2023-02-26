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
                            .onSubmit {
                                Task {
                                    do {
                                        try await signIn()
                                    } catch {
                                        errorMessage = "Oops, something didn’t work. Please try again."
                                    }
                                }
                            }
                        Spacer()
                        Button {
                            Task {
                                idFocus = false
                                do {
                                    try await signIn()
                                } catch {
                                    errorMessage = "Oops, something didn’t work. Please try again."
                                }
                            }
                            
                        } label: {
                            Image(systemName: "arrow.right.circle")
                        }
                        .accessibilityLabel("Sign in with \(userId)")
                        .disabled(userId.isEmpty)
                    }
                }
                Section() {
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
//        .onTapGesture {
//            idFocus = false
//        }
        .sheet(isPresented: $showSignUp) {
            SignUpSheet()
        }
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/#tos")!)
        }
    }
    
    func signIn() async throws {
        if userId.isEmpty { return }
        
        let nameCheck = userId.lowercased()
        let url = URL(string: "https://pastecard.net/api/ios-signin.php?user=" + (nameCheck.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
        
        let (data, response) = try await URLSession.shared.data(from: url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NetworkError.signInError
        }
        let responseString = String(data: data, encoding: .utf8)
        if responseString == "success" {
            Task { await card.signIn(nameCheck) }
        } else {
            errorMessage = "Sorry, the computer can’t find that ID."
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
