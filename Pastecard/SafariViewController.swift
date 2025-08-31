//
//  SafariViewController.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/10/23.
//

import SwiftUI
import SafariServices
import WebKit

struct SafariViewController: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariViewController>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariViewController>) {
    }
}

struct HTMLView: UIViewRepresentable {
    let fileName: String
    let anchor: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "html") else { return }
        guard let htmlString = try? String(contentsOf: url, encoding: .utf8) else { return }
        guard let fullURL = URL(string: "#\(anchor)", relativeTo: url) else { return }
        webView.loadHTMLString(htmlString, baseURL: fullURL)
    }
}
