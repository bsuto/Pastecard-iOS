//
//  SafariViewController.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/10/23.
//

import SwiftUI
import SafariServices

struct SafariViewController: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariViewController>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariViewController>) {
    }
}
