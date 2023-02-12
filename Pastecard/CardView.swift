//
//  ContentView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import Combine
import SwiftUI

struct CardView: View {
    @EnvironmentObject var user: User
    
    @State var text = "Loading…"
    @State private var lastText = ""
    @State private var cancelText = ""
    let charLimit = 1034
    
    @State var online = true
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
                    .onReceive(Just(text)) { _ in enforceLimit(charLimit) }
                    .focused($isFocused)
                    .onChange(of: isFocused) { _ in
                        if isFocused { cancelText = text }
                    }
                    .gesture(DragGesture(minimumDistance: 44, coordinateSpace: .local).onEnded({ value in
                        if value.translation.height < 0 {
                            showMenu.toggle()
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
                                isFocused = false
                            }
                        }
                    }
                    .sheet(isPresented: $showMenu) {
                        SwipeMenu(online: online, uid: user.uid, shareText: text)
                    }
            }
        }
    }
    
    func enforceLimit(_ limit: Int) {
        if text.count > limit {
            Task { @MainActor in
                text = String(text.prefix(limit))
            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView()
    }
}
