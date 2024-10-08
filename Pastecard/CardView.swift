//
//  CardView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import Combine
import SwiftUI

struct CardView: View {
    @EnvironmentObject var card: Pastecard
    @EnvironmentObject var actionService: ActionService
    @Environment(\.scenePhase) var scenePhase
    
    @State private var text = "Loading…"
    @State private var locked = true
    @State private var savedText = ""
    @State private var cancelText = ""
    @State private var showMenu = false
    @State private var showFailAlert = false
    @FocusState private var isFocused: Bool
    @State private var showEmptyState = false
    @State private var animateTip = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: -geo.safeAreaInsets.top) {
                Color("AccentColor")
                    .frame(width: geo.size.width,
                           height: geo.safeAreaInsets.top + 44)
                    .ignoresSafeArea(edges: .top)
                TextEditor(text: $text)
                    .font(Font.body)
                    .frame(alignment: .topLeading)
                    .padding()
                    .focused($isFocused)
                    .scrollDisabled(!isFocused)
                    .onChange(of: isFocused) { _ in
                        if locked {
                            isFocused = false
                        }
                        if !locked && isFocused {
                            cancelText = text
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            showEmptyState = false
                        }
                        if !isFocused && text == "" {
                            showEmptyState = true
                        }
                    }
                    .onReceive(Just(text)) { _ in enforceLimit() }
                    .gesture(DragGesture(minimumDistance: 44, coordinateSpace: .local).onEnded({ value in
                        if value.translation.height < 0 {
                            showMenu = true
                        }
                    }))
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Cancel") {
                                text = cancelText
                                isFocused = false
                            }
                            .foregroundColor(Color(UIColor.link))
                        }
                        ToolbarItem(placement: .keyboard) {
                            Button("Save") {
                                savedText = text
                                Task {
                                    do {
                                        try await setText(card.saveRemote(savedText))
                                    } catch {
                                        saveFailure()
                                    }
                                }
                                locked = true
                                text = "Saving…"
                                isFocused = false
                            }
                            .foregroundColor(Color(UIColor.link))
                        }
                    }
                    .sheet(isPresented: $showMenu) {
                        SwipeMenu(shareText: text)
                    }
                    .alert("Error", isPresented: $showFailAlert, actions: {
                        Button("Cancel", role: .cancel) {
                            text = cancelText
                        }
                        Button("Try Again") {
                            text = savedText
                            isFocused = true
                        }
                    }, message: {
                        Text("There was a problem saving to the cloud.")
                    })
                Image("SwipeUp")
                    .resizable()
                    .frame(width: 48.0, height: 48.0)
                    .padding(.bottom)
                    .foregroundColor(Color(UIColor.placeholderText))
                    .opacity(showEmptyState ? 1 : 0)
                    .offset(y: animateTip ? -80 : 0)
                    .onTapGesture {
                        if #available(iOS 17.0, *) {
                            withAnimation(.easeInOut(duration: 0.5)) { animateTip = true } completion: { withAnimation { animateTip = false }
                            }
                        }
                    }
            }
        }
        .onAppear() { loadText() }
        .onChange(of: scenePhase) { newValue in
            switch newValue {
            case .active:
                performActionIfNeeded()
                card.refreshCalled = true
            default:
                break
            }
        }
        .onChange(of: card.refreshCalled) { newValue in
            if newValue { refreshText() }
        }
    }
    
    func loadText() {
        if isFocused { return }
        Task {
            var loadedText: String
            do {
                loadedText = try await card.loadRemote()
            } catch {
                loadedText = card.loadLocal()
            }
            setText(loadedText)
        }
    }
    
    func refreshText() {
        if isFocused { return }
        card.refreshCalled = false
        locked = true
        text = "Loading…"
        loadText()
    }
    
    func setText(_ returnText: String) {
        locked = false
        text = returnText
        if returnText == "" { showEmptyState = true }
        else { showEmptyState = false }
    }
    
    func saveFailure() {
        locked = false
        showFailAlert = true
    }
    
    func enforceLimit() {
        let charLimit = 1034
        if isFocused && text.count > charLimit {
            Task { @MainActor in
                text = String(text.prefix(charLimit))
            }
        }
    }
    
    func performActionIfNeeded() {
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

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView().environmentObject(Pastecard())
    }
}
