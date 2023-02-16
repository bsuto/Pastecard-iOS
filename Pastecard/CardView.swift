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
    
    @State private var text = "Loading…"
    @State private var locked = true
    @State private var savedText = ""
    @State private var cancelText = ""
    @State private var showMenu = false
    @State private var showFailAlert = false
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
                    .focused($isFocused)
                    .onChange(of: isFocused) { _ in
//                        if locked {
//                            isFocused = false
//                        }
                        if !locked && isFocused {
                            cancelText = text
                        }
                    }
                    .onReceive(Just(text)) { _ in enforceLimit() }
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
                                savedText = text
                                card.saveRemote(savedText)
                                text = "Saving…"
                                
                                isFocused = false
                                locked = true
                            }
                        }
                    }
                    .sheet(isPresented: $showMenu) {
                        SwipeMenu(shareText: text)
                    }
                    .alert("Error", isPresented: $showFailAlert, actions: {
                        Button("Cancel", role: .cancel) {
                            text = cancelText
                        }
                        Button("Try Again") {
                            text = savedText
                            isFocused = true
                        }
                    }, message: {
                        Text("There was a problem saving to the cloud.")
                    })
            }
        }
        .onAppear {
            Task {
                await card.loadRemote()
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
    
    func setText(_ returnText: String) {
        locked = false
        text = returnText
    }
    
    func saveFailure() {
        locked = false
        showFailAlert = true
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView()
    }
}
