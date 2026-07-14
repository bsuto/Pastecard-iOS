import SwiftUI
import AppKit

enum WindowIdentifier {
    static let mainPrefix = "main-AppWindow"
    static let settingsPrefix = "com_apple_SwiftUI_Settings"
}

enum WindowManager {
    // Brings the main card window to front (creating it if needed) and closes the Settings window
    static func resetToMainWindow(openWindow: OpenWindowAction) {
        let mainWindows = NSApplication.shared.windows.filter {
            $0.identifier?.rawValue.hasPrefix(WindowIdentifier.mainPrefix) == true
        }
        // Close any extras, keep the first
        mainWindows.dropFirst().forEach { $0.close() }

        if let mainWindow = mainWindows.first {
            mainWindow.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }

        NSApplication.shared.windows
            .first { $0.identifier?.rawValue.hasPrefix(WindowIdentifier.settingsPrefix) == true }?
            .close()
    }
}
