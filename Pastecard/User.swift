//
//  User.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/12/23.
//

import Combine
import Foundation

class User: ObservableObject {
    @Published var isSignedIn = false
    @Published var uid = ""
    
    func signIn(_ user: String) {
        self.isSignedIn = true
        self.uid = user
    }
    
    func signOut() {
        self.isSignedIn = false
        self.uid = ""
        CardView().text = "Loading…"
        UserDefaults.standard.set("", forKey: "ID")
        UserDefaults.standard.set("", forKey: "text")
    }
    
    func deleteAcct() {
        // API call to delete account
        signOut()
    }
    
    func loadLocal() -> String {
        return UserDefaults.standard.string(forKey: "text") ?? ""
    }

    func loadRemote() -> String {
        var returnText = ""
        
        // GET request
        let url = URL(string: "https://pastecard.net/api/db/" + uid + ".txt")!
        let task = URLSession.shared.downloadTask(with:url) { getUrl, response, error in
            if error != nil {
                // load failure -- alert?
                // returnText = loadLocal()
            }
            if let getUrl = getUrl {
                if let remoteText = try? String(contentsOf: getUrl, encoding: .utf8) {
                    returnText = remoteText
                }
            }
        }
        task.resume()
        
        // if success
        // saveLocal(returnText)
        return returnText
        // WidgetCenter.shared.reloadTimelines(ofKind: "CardWidget")
    }

    func saveLocal(_ text: String) {
        UserDefaults.standard.set(text, forKey: "text")
    }

    func saveRemote(_ text: String) -> Bool {
        // POST request
        var sendText = text
        sendText = sendText.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let postData = ("u=" + uid + "&pc=" + sendText)
        let url = URL(string: "https://pastecard.net/api/write.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: String.Encoding.utf8)
        
        
        // if success
        saveLocal(text)
        // WidgetCenter.shared.reloadTimelines(ofKind: "CardWidget")
        return true
        
        
        // if failure
        // return false
    }
}
