//
//  Pastecard.swift
//  Pastecard
//
//  Created by Brian Sutorius on 2/12/23.
//

import Combine
import Foundation

class Pastecard: ObservableObject {
    @Published var isSignedIn = false
    @Published var uid = ""
    
    init() {
        if let savedUser = UserDefaults.standard.string(forKey: "ID") {
            if !savedUser.isEmpty {
                self.isSignedIn = true
                self.uid = savedUser
            }
        }
    }
    
    func signIn(_ user: String) {
        self.isSignedIn = true
        self.uid = user
        UserDefaults.standard.set(user, forKey: "ID")
        CardView().text = loadRemote()
    }
    
    func signOut() {
        self.isSignedIn = false
        self.uid = ""
        UserDefaults.standard.set("", forKey: "ID")
        UserDefaults.standard.set("", forKey: "text")
        CardView().text = "Loading…"
    }
    
    func deleteAcct() {
        // GET request
        let url = URL(string: "https://pastecard.net/api/ios-deleteacct.php?user=" + (self.uid.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {return}
            let responseString = String(data: data!, encoding: .utf8)
            
            if (responseString == "success") {
                self.signOut()
            } else {
                // if a server error
            }
        }
        task.resume()
    }
    
    func loadLocal() -> String {
        var returnText = ""
        if let localText = UserDefaults.standard.string(forKey: "text") {
            if !localText.isEmpty {
                returnText = localText
            }
        }
        return returnText
    }

    func loadRemote() -> String {
        var returnText = ""
        
        // GET request
        let url = URL(string: "https://pastecard.net/api/db/" + self.uid + ".txt")!
        let task = URLSession.shared.downloadTask(with:url) { getUrl, response, error in
            if error != nil {
                // load failure -- alert?
                // returnText = self.loadLocal()
            }
            if let getUrl = getUrl {
                if let remoteText = try? String(contentsOf: getUrl, encoding: .utf8) {
                    if remoteText.isEmpty {
                        returnText = ""
                    } else {
                        returnText = remoteText
                    }
                }
            }
        }
        task.resume()
        
        // if success
        self.saveLocal(returnText)
        return returnText
        // WidgetCenter.shared.reloadTimelines(ofKind: "CardWidget")
    }
    
    func saveLocal(_ text: String) {
        UserDefaults.standard.set(text, forKey: "text")
    }
    
    func saveRemote(_ text: String) {
        // POST request
        var sendText = text
        sendText = sendText.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let postData = ("user=" + uid + "&text=" + sendText)
        let url = URL(string: "https://pastecard.net/api/ios-write.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: String.Encoding.utf8)
        
        // if success
        saveLocal(text)
        CardView().text = text
        // WidgetCenter.shared.reloadTimelines(ofKind: "CardWidget")
        
        // if failure
        // show alert?
    }
    
    func append(_ text: String) {
        // POST request
        var sendText = text
        sendText = sendText.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let postData = ("user=" + uid + "&text=" + sendText)
        let url = URL(string: "https://pastecard.net/api/ios-append.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: String.Encoding.utf8)
    }
}
