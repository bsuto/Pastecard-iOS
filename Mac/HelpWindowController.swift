// Call HelpWindowController.shared.open() or .open(anchor:) from anywhere.

#if os(macOS)
import AppKit
import WebKit

final class HelpWindowController: NSObject, NSWindowDelegate, WKNavigationDelegate {
    static let shared = HelpWindowController()

    private let baseURL: URL = Bundle.main.url(
        forResource: "help",
        withExtension: "html"
    )!

    private var window: NSWindow?
    private var webView: WKWebView?
    private var backButton: NSButton?
    private var forwardButton: NSButton?
    private var activeNavColor: NSColor    = .white
    private var disabledNavColor: NSColor  = .white.withAlphaComponent(0.35)

    private override init() { super.init() }

    func open(anchor: String? = nil) {
        if let win = window, win.isVisible {
            load(anchor: anchor)
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        buildWindow()
        load(anchor: anchor)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildWindow() {
        let wv = WKWebView(frame: .zero)
        wv.translatesAutoresizingMaskIntoConstraints = false
        wv.navigationDelegate = self
        self.webView = wv

        let activeColor   = NSColor.white
        let disabledColor = NSColor.white.withAlphaComponent(0.35)

        func makeNavButton(_ symbolName: String, accessibilityDescription: String) -> NSButton {
            let cfg   = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription)!
                            .withSymbolConfiguration(cfg)!
            let btn = NSButton(image: image, target: self, action: symbolName.contains("left") ? #selector(goBack) : #selector(goForward))
            btn.bezelStyle = .texturedRounded
            btn.isBordered = false
            btn.isEnabled  = false
            btn.contentTintColor = disabledColor
            return btn
        }

        let back = makeNavButton("chevron.left",  accessibilityDescription: "Back")
        let fwd  = makeNavButton("chevron.right", accessibilityDescription: "Forward")
        self.backButton    = back
        self.forwardButton = fwd

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let toolbar = NSStackView(views: [spacer, back, fwd])
        toolbar.orientation = .horizontal
        toolbar.spacing = 2
        toolbar.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 12)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor(named: "TrademarkBlue")?.cgColor

        self.activeNavColor    = activeColor
        self.disabledNavColor  = disabledColor

        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [toolbar, divider, wv])
        stack.orientation = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.widthAnchor.constraint(equalTo: stack.widthAnchor),
            divider.widthAnchor.constraint(equalTo: stack.widthAnchor),
            wv.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Pastecard Help"
        win.contentMinSize = NSSize(width: 480, height: 360)
        win.contentView = stack
        win.center()
        win.isReleasedWhenClosed = false
        win.delegate = self
        self.window = win
    }

    private func load(anchor: String?) {
        guard let wv = webView else { return }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        if let anchor { components.fragment = anchor }
        guard let url = components.url else { return }

        if wv.url?.absoluteString.hasPrefix(baseURL.absoluteString) == true, let anchor {
            // Already on the help page — just scroll to the anchor via JS
            let js = "document.getElementById('\(anchor)')?.scrollIntoView({behavior:'smooth'});"
            wv.evaluateJavaScript(js, completionHandler: nil)
        } else if baseURL.isFileURL {
            wv.loadFileURL(url, allowingReadAccessTo: baseURL.deletingLastPathComponent())
        } else {
            wv.load(URLRequest(url: url))
        }
    }

    private func updateNavButtons() {
        let canBack = webView?.canGoBack ?? false
        let canFwd  = webView?.canGoForward ?? false
        backButton?.isEnabled        = canBack
        forwardButton?.isEnabled     = canFwd
        backButton?.contentTintColor = canBack ? activeNavColor : disabledNavColor
        forwardButton?.contentTintColor = canFwd ? activeNavColor : disabledNavColor
    }

    @objc private func goBack()    { webView?.goBack() }
    @objc private func goForward() { webView?.goForward() }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateNavButtons()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateNavButtons()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        webView = nil
        backButton = nil
        forwardButton = nil
        activeNavColor = .white
        disabledNavColor = .white.withAlphaComponent(0.35)
    }
}
#endif
