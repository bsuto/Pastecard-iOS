//
//  PCWidget.swift
//  PCWidget
//
//  Created by Brian Sutorius on 4/14/23.
//

import WidgetKit
import SwiftUI
import PastecardCore

@MainActor
struct Provider: @preconcurrency TimelineProvider {
    private let core = PastecardCore.shared
    
    func loadFromLocal() -> String {
        if !core.isSignedIn {
            return "⚠️\n\nPlease sign in first."
        }
        
        return core.loadLocal()
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), text: "Loading…")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), text: loadFromLocal())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let entry = SimpleEntry(date: Date(), text: loadFromLocal())
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct PCWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color("AccentColor"))
                .frame(height:18)
                .widgetAccentable()
            Text(entry.text)
                .padding(12)
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .widgetBackground(backgroundView: Color(UIColor.systemBackground))
    }
}

struct PCWidget: Widget {
    let kind: String = "PCWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PCWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pastecard")
        .description("Shows as much of your card as will fit.")
        .contentMarginsDisabled()
    }
}

extension View {
    func widgetBackground(backgroundView: some View) -> some View {
        return containerBackground(for: .widget) {
            backgroundView
        }
        
    }
}

struct PCWidget_Previews: PreviewProvider {
    static var previews: some View {
        PCWidgetEntryView(entry: SimpleEntry(date: Date(), text: "Eggs, milk, bread"))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
