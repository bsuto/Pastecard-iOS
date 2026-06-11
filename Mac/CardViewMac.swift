#if os(macOS)

import SwiftUI
import AppKit
import PastecardCore

struct WindowDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}
    
    class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
        // Pass through clicks so the view doesn't swallow right-clicks etc.
        override func rightMouseDown(with event: NSEvent) {
            super.rightMouseDown(with: event)
        }
    }
}

struct WindowStateReader: NSViewRepresentable {
    var onFullScreenChange: (Bool) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.onFullScreenChange = onFullScreenChange
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        context.coordinator.observe(window: window)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator {
        var onFullScreenChange: ((Bool) -> Void)?
        private var observed: NSWindow?
        private var hasResignedInitialFocus = false
        
        func observe(window: NSWindow) {
            guard window !== observed else { return }
            observed = window
            if !hasResignedInitialFocus {
                hasResignedInitialFocus = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    window.makeFirstResponder(nil)
                }
            }
            NotificationCenter.default.addObserver(
                forName: NSWindow.didEnterFullScreenNotification,
                object: window, queue: .main
            ) { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    self?.onFullScreenChange?(true)
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: NSWindow.didExitFullScreenNotification,
                object: window, queue: .main
            ) { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    self?.onFullScreenChange?(false)
                }
            }
        }
    }
}

struct KeyCommandHandler: NSViewRepresentable {
    var isEditing: Bool
    var onSave: () -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isEditing = isEditing
        context.coordinator.onSave = onSave
        context.coordinator.onCancel = onCancel
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var isEditing = false
        var onSave: (() -> Void)?
        var onCancel: (() -> Void)?
        private var monitor: Any?

        init() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isEditing else { return event }
                let cmd = event.modifierFlags.contains(.command)
                switch event.keyCode {
                case 53: // Escape
                    self.onCancel?()
                    return nil
                case 36 where cmd: // Command-Return
                    self.onSave?()
                    return nil
                case 47 where cmd: // Command-Period
                    self.onCancel?()
                    return nil
                default:
                    return event
                }
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}

struct MacCardView: View {
    @EnvironmentObject var card: Pastecard
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var editingText = ""
    @State private var isEditing = false
    @State private var showSaveAlert = false
    @State private var showLoadAlert = false
    @FocusState private var isFocused: Bool
    @AppStorage("fontSize") private var fontSize: Double = 13
    @State private var isFullScreen = false
    @State private var keyMonitor: Any?
    @State private var suppressInitialFocus = true
    private var canSave: Bool {
        networkMonitor.isConnected || card.isLocal
    }
    
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
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Title bar spacer
                Color.clear
                    .frame(height: isFullScreen ? 48 : 24)
                    .background(WindowStateReader { fullScreen in
                        isFullScreen = fullScreen
                    })
                
                TextEditor(text: isEditing ? $editingText : .constant(displayText))
                    .font(.system(size: fontSize))
                    .padding()
                    .focused($isFocused)
                    .disabled(card.loadingState == .loading || card.loadingState == .saving || !isEditing)
                    .onChange(of: editingText) { _, _ in
                        if isEditing { enforceLimit() }
                    }
                    .overlay {
                        if !isEditing {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    startEditing()
                                }
                        }
                    }
                
                editButtons
            }
            
            Color("TrademarkBlue")
                .frame(height: 44)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            
            WindowDragRegion()
                .frame(height: 44)
                .ignoresSafeArea(edges: .top)
            
            KeyCommandHandler(
                isEditing: isEditing,
                onSave: saveText,
                onCancel: cancelEditing
            )
            .frame(width: 0, height: 0)
        }
        
        .frame(minWidth: 250, minHeight: 347)
        .background(Color(NSColor.textBackgroundColor))
        .task {
            await checkRefresh()
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
        .onChange(of: card.currentText) { _, _ in
            if !isEditing {
                editingText = card.currentText
            }
        }
        .alert("Save Error", isPresented: $showSaveAlert) {
            Button("Cancel", role: .cancel) {
                cancelEditing()
            }
            Button("Try Again") {
                saveText()
            }
        } message: {
            Text("There was a problem saving to the cloud.")
        }
        .alert("Load Error", isPresented: $showLoadAlert) {
            Button("OK", role: .cancel) {}
            Button("Try Again") {
                refresh()
            }
        } message: {
            Text("There was a problem loading from the cloud.")
        }
    }
    
    private var editButtons: some View {
        HStack {
            if isEditing {
                Button("Cancel") {
                    cancelEditing()
                }
                // .keyboardShortcut(.escape)
                // .keyboardShortcut(".", modifiers: .command)
                
                Spacer()
                
                Button("Save") {
                    saveText()
                }
                .keyboardShortcut("s", modifiers: .command)
                // .keyboardShortcut(.return, modifiers: .command)
                .disabled(!canSave)
            }
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - Actions
    
    private func handleFocusChange(_ focused: Bool) {
        if focused && !isEditing {
            startEditing()
        }
    }
    
    private func setupWindow() {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.minSize = NSSize(width: 250, height: 347)
    }
    
    private func startEditing() {
        isEditing = true
        editingText = card.currentText
        isFocused = true
    }
    
    private func cancelEditing() {
        isEditing = false
        editingText = card.currentText
        isFocused = false
    }
    
    private func saveText() {
        guard isEditing else { return }
        
        let textToSave = editingText
        isEditing = false
        isFocused = false
        
        Task {
            do {
                try await card.save(textToSave)
            } catch {
                await MainActor.run {
                    isEditing = true
                    editingText = textToSave
                    isFocused = true
                    showSaveAlert = true
                }
            }
        }
    }
    
    private func enforceLimit() {
        let charLimit = 1034
        if editingText.count > charLimit {
            editingText = String(editingText.prefix(charLimit))
        }
    }
    
    private func refresh() {
        Task {
            do {
                try await card.refresh()
            } catch {
                showLoadAlert = true
            }
        }
    }
    
    private func checkRefresh() async {
        do {
            try await card.checkRefresh()
        } catch {
            // Silent failure on initial check
        }
    }
}

struct MacCardView_Previews: PreviewProvider {
    static var previews: some View {
        MacCardView()
            .environmentObject(Pastecard())
    }
}

#endif
