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
    
    var is26: Bool {
        if #available(iOS 26.0, *) { return true }
        else { return false }
    }
    
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
                headerView(geo: geo)
                textEditorView
                swipeUpIcon
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            refresh()
        }
    }
    
    private func headerView(geo: GeometryProxy) -> some View {
        Color("TrademarkBlue")
            .frame(width: geo.size.width,
                   height: is26 ? geo.safeAreaInsets.top + 54 : geo.safeAreaInsets.top + 44)
            .ignoresSafeArea(edges: .top)
    }
    
    private var textEditorView: some View {
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
            .gesture(swipeGesture)
            .keyboardToolbar {
                if #available(iOS 26.0, *) {
                    newToolbar
                } else {
                    oldToolbar
                }
            }
            .sheet(isPresented: $showMenu) {
                SwipeMenu(shareText: card.currentText)
            }
            .alert("Oops", isPresented: $showSaveAlert, actions: {
                saveAlertActions
            }, message: {
                Text("There was a problem saving to the cloud.")
            })
            .alert("Oops", isPresented: $showLoadAlert, actions: {
                loadAlertActions
            }, message: {
                Text("There was a problem loading from the cloud.")
            })
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 44, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.height < 0 {
                    showMenu = true
                }
            }
    }
    
    private var saveAlertActions: some View {
        Group {
            Button("Cancel", role: .cancel) {
                cancelEditing()
            }
            Button("Try Again") {
                saveText()
            }
        }
    }
    
    private var loadAlertActions: some View {
        Group {
            Button("Cancel", role: .cancel) {}
            Button("Try Again") {
                refresh()
            }
        }
    }
    
    // MARK: Custom Toolbars
    
    @available(iOS 26.0, *)
    private var newToolbar: some View {
        Group {
            HStack {
                Button {
                    cancelEditing()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(Color("AccentColor"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .glassEffect()
                
                Spacer()
                
                Button {
                    saveText()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(networkMonitor.isConnected ? Color("AccentColor") : Color(UIColor.systemGray))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .glassEffect()
                .disabled(!networkMonitor.isConnected)
            }
        }
    }
    
    private var oldToolbar: some View {
        Group {
            if !is26 {
                HStack {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .font(.headline)
                    .foregroundColor(Color("AccentColor"))
                    
                    Spacer()
                    
                    Button("Save") {
                        saveText()
                    }
                    .font(.headline)
                    .foregroundColor(networkMonitor.isConnected ? Color("AccentColor") : Color(UIColor.systemGray))
                    .disabled(!networkMonitor.isConnected)
                }
                .padding()
            }
        }
    }
    
    // MARK: Edit & Save functions
    
    private func startEditing() {
        isEditing = true
        editingText = card.currentText
        isFocused = true
        showEmptyState = false
        NotificationCenter.default.post(name: .editingDidStart, object: nil)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func cancelEditing() {
        isEditing = false
        editingText = ""
        isFocused = false
        updateEmptyState()
        NotificationCenter.default.post(name: .editingDidEnd, object: nil)
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
        NotificationCenter.default.post(name: .editingDidEnd, object: nil)
        
        Task {
            do {
                try await card.save(textToSave)
                await MainActor.run { updateEmptyState() }
            } catch {
                // Re-enter editing mode with the text they were trying to save
                isEditing = true
                editingText = textToSave
                NotificationCenter.default.post(name: .editingDidStart, object: nil)
                showSaveAlert = true
            }
        }
    }
    
    // MARK: Icon helpers
    
    private var swipeUpIcon: some View {
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
                updateEmptyState()
                return
            }
            
            // Refresh if in background for 60 seconds
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

// MARK: Custom toolbar modifier

private struct CustomToolbarModifier<Toolbar: View>: ViewModifier {
    @State private var inEditingMode = false
    private let toolbar: Toolbar
    
    init(@ViewBuilder toolbar: () -> Toolbar) {
        self.toolbar = toolbar()
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if inEditingMode {
                    if #available(iOS 26.0, *) {
                        toolbar
                            .padding(18)
                    } else {
                        toolbar
                        // .safeAreaPadding(.bottom, 12) // needed for simulators but not real devices??
                            .background(.bar)
                            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color(UIColor.systemFill)), alignment: .top)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .editingDidStart)) { _ in
                withAnimation(.easeIn(duration: 0.2)) {
                    inEditingMode = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .editingDidEnd)) { _ in
                inEditingMode = false
            }
    }
}

extension View {
    func keyboardToolbar<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(CustomToolbarModifier(toolbar: content))
    }
}

extension Notification.Name {
    static let refreshRequested = Notification.Name("refreshRequested")
    static let editingDidStart = Notification.Name("editingDidStart")
    static let editingDidEnd = Notification.Name("editingDidEnd")
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView().environmentObject(Pastecard())
    }
}
