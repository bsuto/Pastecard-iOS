//
//  CardWidget.swift
//  CardWidget
//
//  Created by Brian Sutorius on 1/5/21.
//  Copyright © 2021 Brian Sutorius. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
	let defaults = UserDefaults(suiteName: "group.net.pastecard")
	
	func loadRemote() -> String {
		let path = "https://pastecard.net/api/db/"
		let user = defaults!.string(forKey: "username")
		let textExtension = ".txt"
		var remoteText = "😬\n\nSomething went wrong"
		
		if let cardURL = URL(string: path + user! + textExtension) {
			do {
				let contents = try String(contentsOf: cardURL)
				remoteText = contents
			} catch {}
		} else {
			remoteText = "Please sign in, in the app."
		}
		return remoteText
	}
	
	func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), cardText: "Loading…")
	}
	
	func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
		let entry = SimpleEntry(date: Date(), cardText: "Loading…")
		completion(entry)
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
		let currentDate = Date()
		let refreshDate = Calendar.current.date(byAdding: .minute, value: 50, to: currentDate)!
		let widgetText = loadRemote()
		
		let entry = SimpleEntry(date: currentDate, cardText: widgetText)
		let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
		completion(timeline)
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let cardText: String
}

struct CardWidgetEntryView : View {
	var entry: Provider.Entry
	
	var body: some View {
		VStack(spacing: 0) {
			Rectangle()
				.fill(Color("AccentColor"))
				.frame(height:18)
			Text(entry.cardText)
				.padding(12)
				.font(.body)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		}
		.background(Color("WidgetBackground"))
	}
}

@main
struct CardWidget: Widget {
	private let kind: String = "CardWidget"
	
	public var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			CardWidgetEntryView(entry: entry)
		}
		.configurationDisplayName("Pastecard")
		.description("Shows as much of your card as will fit.")
	}
}

struct CardWidget_Previews: PreviewProvider {
	static var previews: some View {
		CardWidgetEntryView(entry: SimpleEntry(date: Date(), cardText: "Loading…"))
			.previewContext(WidgetPreviewContext(family: .systemMedium))
	}
}
