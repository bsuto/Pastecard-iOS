//
//  CardView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import Combine
import SwiftUI
import PastecardCore

struct CardView: View {
    @EnvironmentObject var card: Pastecard
    @EnvironmentObject var actionService: ActionService
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var editingText = ""
    @State private var isEditing = false
    @State private var showMenu = false
    @State private var showSaveAlert = false
    @State private var showLoadAlert = false
    @FocusState private var isFocused: Bool
    @State private var showEmptyState = false
    @State private var animateTip = false
    
    // Debounced loading to prevent excessive refreshes
    @State private var loadTask: Task<Void, Never>?
    
    var displayText: String {
        if isEditing {
            return editingText
        } else {
            switch card.loadingState {
            case .loading:
                return "Loading…"
            case .saving:
                return "Saving…"
            case .idle, .loaded, .error:
                return card.currentText
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: -geo.safeAreaInsets.top) {
                Color("AccentColor")
                    .frame(width: geo.size.width,
                           height: geo.safeAreaInsets.top + 44)
                    .ignoresSafeArea(edges: .top)
                
                TextEditor(text: isEditing ? $editingText : .constant(displayText))
                    .font(Font.body)
                    .frame(alignment: .topLeading)
                    .padding()
                    .focused($isFocused)
                    .scrollDisabled(!isFocused)
                    .onChange(of: isFocused) { _, newValue in
                        handleFocusChange(newValue)
                    }
                    .onReceive(Just(editingText)) { _ in
                        if isEditing { enforceLimit() }
                    }
                    .gesture(DragGesture(minimumDistance: 44, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.height < 0 {
                                showMenu = true
                            }
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Cancel") {
                                cancelEditing()
                            }
                            .foregroundColor(Color(UIColor.link))
                        }
                        ToolbarItem(placement: .keyboard) {
                            Button("Save") {
                                saveText()
                            }
                            .foregroundColor(Color(UIColor.link))
                        }
                    }
                    .sheet(isPresented: $showMenu) {
                        SwipeMenu(shareText: card.currentText)
                    }
                    .alert("Error", isPresented: $showSaveAlert, actions: {
                        Button("Cancel", role: .cancel) {
                            cancelEditing()
                        }
                        Button("Try Again") {
                            saveText()
                        }
                    }, message: {
                        Text("There was a problem saving to the cloud.")
                    })
                    .alert("Error", isPresented: $showLoadAlert, actions: {
                        Button("Cancel", role: .cancel) {}
                        Button("Try Again") {
                            Task {
                                do {
                                    try await card.refresh()
                                } catch {
                                    showLoadAlert = true
                                    throw NetworkError.loadError
                                }
                            }
                            updateEmptyState()
                        }
                    }, message: {
                        Text("There was a problem loading from the cloud.")
                    })
                
                Image("SwipeUp")
                    .resizable()
                    .frame(width: 48.0, height: 48.0)
                    .padding(.bottom)
                    .foregroundColor(Color(UIColor.placeholderText))
                    .opacity(showEmptyState ? 1 : 0)
                    .offset(y: animateTip ? -80 : 0)
                    .onTapGesture {
                        animateSwipeUpTip()
                    }
            }
        }
        .task { // Initial load when view appears
            await loadTextIfOld()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: card.currentText) { _, _ in
            updateEmptyState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            Task {
                do {
                    try await card.refresh()
                } catch {
                    showLoadAlert = true
                    throw NetworkError.loadError
                }
            }
            updateEmptyState()
        }
    }
    
    private func loadTextIfOld() async {
        if Date().timeIntervalSince(card.lastRefreshTime) > 30 { // 30 seconds
            Task {
                do {
                    try await card.refresh()
                } catch {
                    showLoadAlert = true
                    throw NetworkError.loadError
                }
            }
        }
        updateEmptyState()
    }
    
    private func handleFocusChange(_ focused: Bool) {
        if focused && !isEditing {
            startEditing()
        } else if !focused && isEditing {
            // User tapped away without saving - this is just canceling
            cancelEditing()
        }
    }
    
    private func startEditing() {
        isEditing = true
        editingText = card.currentText
        isFocused = true
        showEmptyState = false
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func cancelEditing() {
        isEditing = false
        editingText = ""
        isFocused = false
        updateEmptyState()
    }
    
    private func saveText() {
        guard isEditing else { return }
        guard networkMonitor.isConnected else { return }
        
        let textToSave = editingText
        isEditing = false
        isFocused = false
        
        Task {
            do {
                try await card.save(textToSave)
                updateEmptyState()
            } catch {
                // Re-enter editing mode with the text they were trying to save
                isEditing = true
                editingText = textToSave
                showSaveAlert = true
            }
        }
    }
    
    private func updateEmptyState() {
        showEmptyState = !isEditing && card.currentText.isEmpty
    }
    
    private func enforceLimit() {
        let charLimit = 1034
        if editingText.count > charLimit {
            editingText = String(editingText.prefix(charLimit))
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            performActionIfCalled()
            // Debounced refresh when coming back to foreground
            loadTask?.cancel()
            loadTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if !Task.isCancelled {
                    await loadTextIfOld()
                }
            }
        case .background:
            // Cancel any pending loads when going to background
            loadTask?.cancel()
        default:
            break
        }
    }
    
    private func animateSwipeUpTip() {
        withAnimation(.easeInOut(duration: 0.5)) {
            animateTip = true
        } completion: {
            withAnimation {
                animateTip = false
            }
        }
    }
    
    private func performActionIfCalled() {
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

extension Notification.Name {
    static let refreshRequested = Notification.Name("refreshRequested")
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView().environmentObject(Pastecard())
    }
}
