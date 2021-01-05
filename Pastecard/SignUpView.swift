//
//  SignUpView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/16/20.
//

import SwiftUI
import SafariServices

struct SignUpView: View {
	
	@State private var username: String = ""
	@State private var isEditing = false
	
	var body: some View {
		GeometryReader { metrics in
			VStack(alignment: .leading) {
				Spacer()
				Text("Sign In")
					.font(.largeTitle)
					.fontWeight(.bold)
					.padding()
				HStack(spacing: 0) {
					Text("pastecard.net/")
						.padding(0)
					TextField(
						"username",
						text: $username
					) { isEditing in
						self.isEditing = isEditing
					} onCommit: {
						
					}
					.autocapitalization(.none)
					.disableAutocorrection(true)
					.background(Color(.secondarySystemBackground))
				}
				.padding()
				HStack {
					Button(action: {}) {
						Text("Sign Up")
							.frame(width: metrics.size.width * 0.40, alignment: .center)
							.padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
							.background(Color(.secondarySystemBackground))
					}
					Spacer()
					Button(action: {}) {
						Text("Go")
							.fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
							.frame(width: metrics.size.width * 0.40, alignment: .center)
							.padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
							.background(Color(.secondarySystemBackground))
					}.disabled(username.count == 0)
				}
				.padding()
				Text("Privacy & Terms")
					.font(.caption)
					.foregroundColor(.gray)
					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
					.padding()
					.onTapGesture {
						let tosUrl = URL(string: "https://pastecard.net/help/#tos")
						let svc = SFSafariViewController(url: tosUrl!)
						UIApplication.shared.windows.first?.rootViewController?.present(svc, animated: true, completion: nil)
					}
			}
		}
	}
}

struct SignUpView_Previews: PreviewProvider {
	static var previews: some View {
		SignUpView()
	}
}
