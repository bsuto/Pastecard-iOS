import SafariServices

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        guard let dict = message as? [String: Any],
              let text = dict["text"] as? String else {
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let core = PastecardCore.shared
        guard core.isSignedIn else {
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        Task {
            try? await core.append(text)
            context.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
