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
            self.isSignedIn = true
            self.uid = savedUser
        }
    }
    
    func signIn(_ user: String) async {
        self.isSignedIn = true
        self.uid = user
        UserDefaults.standard.set(user, forKey: "ID")
        await loadRemote()
    }
    
    func signOut() {
        self.isSignedIn = false
        self.uid = ""
        UserDefaults.standard.set("", forKey: "ID")
        UserDefaults.standard.set("", forKey: "text")
        CardView().setText("Loading…")
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
                // server error
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

    func loadRemote() async {
        var returnText = ""
        
        do {
            let url = URL(string: "https://pastecard.net/api/db/" + self.uid + ".txt")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let remoteText = String(decoding: data, as: UTF8.self)
            
            if !remoteText.isEmpty {
                returnText = remoteText
            }
        } catch {
            returnText = loadLocal()
        }
        
        self.saveLocal(returnText)
        await CardView().setText(returnText)
    }
    
    func saveLocal(_ text: String) {
        UserDefaults.standard.set(text, forKey: "text")
    }
    
    func saveRemote(_ text: String) {
        // legacy POST request
        let sendText = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let postData = ("user=" + self.uid + "&text=" + sendText)
        let url = URL(string: "https://pastecard.net/api/ios-write.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: String.Encoding.utf8)
        request.timeoutInterval = 5
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                CardView().saveFailure()
            } else {
                self.saveLocal(text)
                CardView().setText(text)
                // WidgetCenter.shared.reloadTimelines(ofKind: "CardWidget")
            }
        }.resume()
    }
    
    func append(_ text: String) {
        // legacy POST request
        let sendText = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let postData = ("user=" + self.uid + "&text=" + sendText)
        let url = URL(string: "https://pastecard.net/api/ios-append.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                // extension failure?
            }
        }.resume()
    }
    
    // widgetLoad ?
}
