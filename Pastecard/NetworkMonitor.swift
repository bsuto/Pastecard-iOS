//
//  NetworkMonitor.swift
//  Pastecard
//
//  Created by Brian Sutorius on 7/1/25.
//

import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
