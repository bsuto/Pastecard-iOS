//
//  CardView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

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
    
    // Keep track of when to refresh
    @State private var lastBackgroundTime: Date?
    @State private var hasBeenActiveOnce = false
    @State private var loadTask: Task<Void, Never>?
    @AppStorage("lastRefreshedDate") private var lastRefreshedDate: Double = 0
    
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
                Color("TrademarkBlue")
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
                    .onChange(of: editingText) { _, _ in
                        if isEditing { enforceLimit() }
                    }
                    .gesture(DragGesture(minimumDistance: 44, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.height < 0 {
                                showMenu = true
                            }
                        }
                    )
                    .keyboardToolbar(content: {
                        HStack {
                            Button("Cancel") {
                                cancelEditing()
                            }
                            .font(.headline)
                            .foregroundColor(Color("AccentColor"))
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            Button("Save") {
                                saveText()
                            }
                            .font(.headline)
                            .foregroundColor(networkMonitor.isConnected ? Color("AccentColor") : Color(UIColor.systemGray))
                            .disabled(!networkMonitor.isConnected)
                            .padding(.horizontal)
                        }
                    })
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
                            refresh()
                        }
                    }, message: {
                        Text("There was a problem loading from the cloud.")
                    })
                
                Image("SwipeUp")
                    .resizable()
                    .frame(width: 48.0, height: 48.0)
                    .padding(.bottom, showEmptyState ? nil : 0)
                    .foregroundColor(Color(UIColor.placeholderText))
                    .opacity(showEmptyState ? 1 : 0)
                    .offset(y: animateTip ? -80 : 0)
                    .onTapGesture {
                        animateSwipeUpTip()
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            refresh()
        }
    }
    
    // MARK: Edit & Save functions
    
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
    
    private func handleFocusChange(_ focused: Bool) {
        if focused && !isEditing {
            startEditing()
        } else if !focused && isEditing {
            // User tapped away without saving, i.e. cancel
            cancelEditing()
        }
    }
    
    private func enforceLimit() {
        let charLimit = 1034
        if editingText.count > charLimit {
            editingText = String(editingText.prefix(charLimit))
        }
    }
    
    private func saveText() {
        guard isEditing else { return }
        
        let textToSave = editingText
        isEditing = false
        isFocused = false
        
        Task {
            do {
                try await card.save(textToSave)
                await MainActor.run { updateEmptyState() }
            } catch {
                // Re-enter editing mode with the text they were trying to save
                isEditing = true
                editingText = textToSave
                showSaveAlert = true
            }
        }
    }
    
    // MARK: Icon helpers
    
    private func updateEmptyState() {
        showEmptyState = !isEditing && card.currentText.isEmpty
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
    
    private func swapIconAction() {
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
    
    // MARK: Refresh functions
    
    private func refresh() {
        Task {
            do {
                try await card.refresh()
                await MainActor.run {
                    updateEmptyState()
                    let now = Date()
                    card.lastRefreshed = now
                    lastRefreshedDate = now.timeIntervalSince1970
                }
            } catch {
                showLoadAlert = true
                throw NetworkError.loadError
            }
        }
    }
    
    private func refreshIfNeeded() {
        let last = Date(timeIntervalSince1970: lastRefreshedDate)
        let elapsed = Date().timeIntervalSince(last)
        guard elapsed > 60 else { return } // 60 seconds
        
        loadTask?.cancel()
        loadTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
            
            if !Task.isCancelled {
                await MainActor.run {
                    refresh()
                }
            }
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            swapIconAction()
            
            // Cold launch
            if !hasBeenActiveOnce {
                hasBeenActiveOnce = true
                refreshIfNeeded()
                lastBackgroundTime = nil
                return
            }

            // Refresh if in background 60 seconds
            if let bgTime = lastBackgroundTime,
               Date().timeIntervalSince(bgTime) > 60 {
                refreshIfNeeded()
            }
            
            lastBackgroundTime = nil
            
        case .background:
            loadTask?.cancel()
            
            // Only set background time if still in background after 5 seconds
            if !isEditing {
                loadTask = Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if !Task.isCancelled {
                        await MainActor.run {
                            if scenePhase == .background {
                                lastBackgroundTime = Date()
                            }
                        }
                    }
                }
            }
        case .inactive:
            break // Don't treat inactive as background time
        default:
            break
        }
    }
}

extension Notification.Name {
    static let refreshRequested = Notification.Name("refreshRequested")
}

// MARK: - Keyboard Toolbar Modifier

private struct KeyboardToolbarModifier<Toolbar: View>: ViewModifier {
    @State private var isKeyboardShown = false
    private let toolbar: Toolbar
    
    init(@ViewBuilder toolbar: () -> Toolbar) {
        self.toolbar = toolbar()
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isKeyboardShown {
                    toolbar
                        .frame(height: 46)
                        .background(.bar)
                        .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color(UIColor.systemFill)), alignment: .top)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeIn(duration: 0.2)) {
                    isKeyboardShown = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardShown = false
            }
    }
}

extension View {
    func keyboardToolbar<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(KeyboardToolbarModifier(toolbar: content))
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView().environmentObject(Pastecard())
    }
}
