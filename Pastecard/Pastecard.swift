//
//  Pastecard.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/10/23.
//

import Foundation

func loadLocal() -> String {
    return UserDefaults.standard.string(forKey: "text") ?? ""
}

func loadRemote(_ id: String) -> String {
    var returnText = ""
    
    // GET request
    let url = URL(string: "https://pastecard.net/api/db/" + id + ".txt")!
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

func saveRemote(_ id: String, _ text: String) -> Bool {
    // POST request
    var sendText = text
    sendText = sendText.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    let postData = ("u=" + id + "&pc=" + sendText)
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

