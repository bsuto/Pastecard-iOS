//
//  ContentView.swift
//  Pastecard
//
//  Created by Brian Sutorius on 1/1/23.
//

import SwiftUI

struct ContentView: View {
    @State var text = "Loading…"
    @State private var lastText = ""
    @State private var oldText = ""
    
    @State var uid = ""
    @State var online = true
    
    @State private var showMenu = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: -geometry.safeAreaInsets.top) {
                Color("TrademarkBlue")
                    .frame(width: geometry.size.width,
                           height: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
                    .padding(.bottom, 0)
                TextEditor(text: $text)
                    .frame(alignment: .topLeading)
                    .padding()
                    .font(Font.body)
                    .onChange(of: text, perform: { newText in
                        if text.count <= 1034 {
                            lastText = text
                        } else {
                            self.text = lastText
                        }
                    })
                    .onAppear{
                        oldText = text
                    }
                    .focused($isFocused)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Cancel") {
                                text = oldText
                                isFocused = false
                            }
                        }
                        ToolbarItem(placement: .keyboard) {
                            Button("Save") {
                                isFocused = false
                                showMenu.toggle()
                            }
                            .bold()
                        }
                    }
                    .sheet(isPresented: $showMenu) {
                        SwipeMenu(online: online, uid: uid)
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
