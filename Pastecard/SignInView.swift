//
//  SignInView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import Combine
import SwiftUI
import PastecardCore

struct SignInView: View {
    @EnvironmentObject var card: Pastecard
    @EnvironmentObject var actionService: ActionService
    @Environment(\.scenePhase) var scenePhase
    
    @State private var userId = ""
    @State private var showSignUp = false
    @State private var showSVC = false
    @State private var errorMessage = ""
    @FocusState private var idFocus: Bool
    let impact = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        GeometryReader { geo in
            List {
                HStack(alignment: .center) {
                    Text("Pastecard")
                    .font(Font.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.primary.opacity(0))
                .onTapGesture {
                    if idFocus {
                        idFocus = false
                    }
                }
                Section(header: Text("Sign In")) {
                    HStack(spacing:0) {
                        Text("pastecard.net/")
                        TextField("ID", text: $userId)
                            .focused($idFocus)
                            .submitLabel(.go)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onSubmit {
                                Task {
                                    do {
                                        try await signIn()
                                    } catch {
                                        errorMessage = "Oops, something didn’t work. Please try again."
                                    }
                                }
                            }
                            .onChange(of: userId) { _, newValue in
                                if userId == "" {
                                    errorMessage = ""
                                }
                            }
                            .onChange(of: idFocus) { _, newValue in
                                if idFocus { impact.impactOccurred() }
                            }
                        Spacer()
                        Button {
                            Task {
                                do {
                                    try await signIn()
                                } catch {
                                    errorMessage = "Oops, something didn’t work. Please try again."
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(userId.isEmpty ? Color(UIColor.placeholderText): Color(UIColor.link))
                        }
                        .accessibilityLabel("Sign in with \(userId)")
                        .disabled(userId.isEmpty)
                    }
                }
                Section() {
                    Text(errorMessage)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, -8)
                        .foregroundColor(.red)
                        .listRowBackground(Color.primary.opacity(0))
                }
                Section(header: Text("Create a Pastecard")) {
                    Button {
                        impact.impactOccurred()
                        idFocus = false
                        showSignUp = true
                    } label: {
                        Text("Sign Up")
                    }
                    .foregroundColor(Color(UIColor.link))
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
            .scrollDisabled(true)
            .safeAreaInset(edge: .top) {
                Color("AccentColor")
                    .frame(width: geo.size.width,
                           height: geo.safeAreaInsets.top + 44)
                    .padding(.top, -geo.safeAreaInsets.top)
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                performActionIfCalled()
            default:
                break
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpSheet()
        }
        .sheet(isPresented: $showSVC) {
            SafariViewController(url: URL(string: "https://pastecard.net/help/#tos")!)
                .ignoresSafeArea()
        }
    }
    
    func signIn() async throws {
        if userId.isEmpty { return }
        idFocus = false
        
        let nameCheck = userId.lowercased().trimmingCharacters(in: .whitespaces)
        let url = URL(string: "https://pastecard.net/api/ios-signin.php?user=" + (nameCheck.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
        
        var request = URLRequest(url: url!)
        request.timeoutInterval = 10.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NetworkError.signInError
        }
        let responseString = String(data: data, encoding: .utf8)
        if responseString == "success" {
            Task {
                do {
                    try await card.signIn(nameCheck)
                } catch {
                    throw NetworkError.signInError
                }
            }
        } else {
            errorMessage = "Sorry, the computer can’t find that ID."
        }
    }
    
    func performActionIfCalled() {
        guard let action = actionService.action else { return }
        
        switch action {
        case .swapIcon:
            if UIApplication.shared.supportsAlternateIcons {
                if UIApplication.shared.alternateIconName == "AltIcon" {
                    UIApplication.shared.setAlternateIconName(nil)
                } else {
                    UIApplication.shared.setAlternateIconName("AltIcon")
                }
            }
        }
        
        actionService.action = nil
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
