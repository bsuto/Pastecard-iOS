//
//  CardView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/16/20.
//

import SwiftUI
import SafariServices

struct CardView: View {
	@State private var cardText = "Loading…"
	@State private var cardLock = true
	@State private var showActionSheet = false
	
	// delete default text view background
	init() {
		UITextView.appearance().backgroundColor = .clear
	}
	
	var body: some View {
		GeometryReader { metrics in
			VStack {
				Spacer()
				HStack {
					TextEditor(text: $cardText)
						.padding(EdgeInsets(top: 24, leading: 4, bottom: 4, trailing: 4))
						.background(Color("fafafa").shadow(color: Color("shadowOff"), radius: 4))
						.overlay(Rectangle().frame(width: nil, height: 24, alignment: .top).foregroundColor(Color("trademarkBlue")), alignment: .top)
						.font(.body)
						.onTapGesture {
							
						}
						.onLongPressGesture {
							self.showActionSheet = true
						}
						.actionSheet(isPresented: $showActionSheet) {
									ActionSheet(
										title: Text("Pastecard for iOS"), message: Text("version 2.0"), buttons: [
											.cancel(Text("OK")) { print(self.showActionSheet) },
											.default(Text("Help")) {
												let helpUrl = URL(string: "https://pastecard.net/help/")
												let svc = SFSafariViewController(url: helpUrl!)
												UIApplication.shared.windows.first?.rootViewController?.present(svc, animated: true, completion: nil)
											},
											.default(Text("Refresh")) {},
											.default(Text("Share…")) { let text = [ $cardText ]
												let avc = UIActivityViewController(activityItems: text as [Any], applicationActivities: nil)
				  UIApplication.shared.windows.first?.rootViewController?.present(avc, animated: true, completion: nil) },
											.destructive(Text("Sign Out")) {}
										]
									)
								}
				}.padding()
				HStack {
					Spacer()
					Button(action: {
						
					}) {
						Text("Cancel")
							.fontWeight(.heavy)
							.padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
							.foregroundColor(Color("buttonAccent"))
							.background(Color(UIColor.systemBackground))
							.overlay(
								RoundedRectangle(cornerRadius: 16)
									.stroke(Color("buttonAccent"), lineWidth: 4)
							)
					}
					Spacer()
					Button(action: {
						
					}) {
						Text("Save")
							.fontWeight(.heavy)
							.padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
							.foregroundColor(Color("buttonAccent"))
							.background(Color(UIColor.systemBackground))
							.overlay(
								RoundedRectangle(cornerRadius: 16)
									.stroke(Color("buttonAccent"), lineWidth: 4)
							)
					}
					Spacer()
				}
				Spacer()
					.frame(height: metrics.size.height * 0.10)
			}
		}
	}
	func cleanUp() {
		
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		CardView()
	}
}
