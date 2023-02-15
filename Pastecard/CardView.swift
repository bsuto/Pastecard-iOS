//
//  CardView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import Combine
import SwiftUI

struct CardView: View {
    @EnvironmentObject var card: Pastecard
    
    @State var text = "Loading…"
    @State private var lastText = ""
    @State private var cancelText = ""
    @State private var showMenu = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: -geo.safeAreaInsets.top) {
                Color("TrademarkBlue")
                    .frame(width: geo.size.width,
                           height: geo.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
                TextEditor(text: $text)
                    .font(Font.body)
                    .frame(alignment: .topLeading)
                    .padding()
                    .onReceive(Just(text)) { _ in enforceLimit() }
                    .focused($isFocused)
                    .gesture(DragGesture(minimumDistance: 44, coordinateSpace: .local).onEnded({ value in
                        if value.translation.height < 0 {
                            showMenu = true
                        }
                    }))
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Cancel") {
                                text = cancelText
                                isFocused = false
                            }
                        }
                        ToolbarItem(placement: .keyboard) {
                            Button("Save") {
                                let saveText = text
                                card.saveRemote(saveText)
                                text = "Saving…"
                                
                                isFocused = false
                            }
                        }
                    }
                    .sheet(isPresented: $showMenu) {
                        SwipeMenu(shareText: text)
                    }
            }
        }
    }
    
    func enforceLimit() {
        let charLimit = 1034
        if text.count > charLimit {
            Task { @MainActor in
                text = String(text.prefix(charLimit))
            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView()
    }
}
