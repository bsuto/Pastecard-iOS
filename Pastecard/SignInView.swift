//
//  SignInView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/8/23.
//

import SwiftUI
import PastecardCore
import WebKit

struct SignInView: View {
    @EnvironmentObject var card: Pastecard
    @ScaledMetric(relativeTo: .body) var textHeight: CGFloat = 24
    @EnvironmentObject var actionService: ActionService
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var networkMonitor = NetworkMonitor()
    
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
                    HStack(spacing: 0) {
                        Text("pastecard.net/")
                            .minimumScaleFactor(0.5)
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
                                .foregroundColor((userId.isEmpty || !networkMonitor.isConnected) ? Color(UIColor.placeholderText): Color("AccentColor"))
                        }
                        .accessibilityLabel("Sign in with \(userId)")
                        .disabled(userId.isEmpty || !networkMonitor.isConnected)
                    }
                    .frame(height: textHeight)
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
                    .frame(height: textHeight)
                    .disabled(!networkMonitor.isConnected)
                    .foregroundColor(networkMonitor.isConnected ? Color("AccentColor") : Color(UIColor.systemGray))
                    
                    Button {
                        idFocus = false
                        showSVC = true
                    } label: {
                        HStack {
                            Text("Privacy & Terms")
                        }
                        .foregroundColor(.primary)
                    }
                    .frame(height: textHeight)
                }
            }
            .scrollDisabled(true)
            .safeAreaInset(edge: .top) {
                Color("TrademarkBlue")
                    .frame(width: geo.size.width,
                           height: geo.safeAreaInsets.top + 44)
                    .padding(.top, -geo.safeAreaInsets.top)
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                swapIconAction()
            default:
                break
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpSheet()
        }
        .sheet(isPresented: $showSVC) {
            if networkMonitor.isConnected {
                SafariViewController(url: URL(string: "https://pastecard.net/help/#tos")!)
                    .ignoresSafeArea()
            } else {
                if #available(iOS 26.0, *) {
                    ZStack {
                        WebView(
                            url: URL(string: "#tos", relativeTo: Bundle.main.url(forResource: "help", withExtension: "html"))
                        )
                        VStack() {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    showSVC = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.primary)
                                        .font(.title)
                                        .padding()
                                }
                                .accessibilityLabel("Done")
                                .glassEffect()
                                .padding()
                            }
                        }
                    }
                }
                else {
                    VStack(spacing: 0) {
                        HStack {
                            Button("Done") {
                                showSVC = false
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.bar)
                        .overlay(Rectangle().frame(width: nil, height: 1, alignment: .bottom).foregroundColor(Color(UIColor.systemFill)), alignment: .bottom)
                        HTMLView(fileName: "help", anchor: "tos")
                    }
                }
            }
        }
    }
    
    func signIn() async throws {
        if userId.isEmpty { return }
        idFocus = false
        
        let nameCheck = userId.lowercased().trimmingCharacters(in: .whitespaces)
        let url = URL(string: "https://pastecard.net/api/users/" + nameCheck)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        let (_, response) = try await URLSession(configuration: .ephemeral).data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            if statusCode == 200 {
                Task {
                    do {
                        try await card.signIn(nameCheck)
                    } catch {
                        throw NetworkError.signInError
                    }
                }
            } else if statusCode == 404 {
                errorMessage = "Sorry, the computer can’t find that ID."
            } else {
                errorMessage = "Oops, something didn’t work. Please try again."
            }
        }
    }
    
    func swapIconAction() {
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
