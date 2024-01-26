//
//  SwiftUIView.swift
//  PCShareExt
//
//  Created by Brian Sutorius on 4/18/23.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        VStack(spacing:0) {
            Rectangle()
                .fill(Color("TrademarkBlue"))
                .frame(maxWidth: .infinity, maxHeight: 18)
            Text("Saving…")
                .font(.title2)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, maxHeight: 96)
                .background(Color(UIColor.secondarySystemBackground))
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
