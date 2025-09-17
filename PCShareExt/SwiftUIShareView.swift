//
//  SwiftUIView.swift
//  PCShareExt
//
//  Created by Brian Sutorius on 4/18/23.
//

import SwiftUI

struct SwiftUIShareView: View {
    var is26: Bool {
        if #available(iOS 26, *) { return true }
        else { return false }
    }
    
    var body: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color("TrademarkBlue"))
                    .frame(height: is26 ? 36 : 18)
                
                Text("Saving…")
                    .font(.title2)
                    .padding(.top, is26 ? 0 : 16)
                    .frame(maxWidth: .infinity, maxHeight: is26 ? .infinity : 96)
                    .background(Color(UIColor.secondarySystemBackground))
            }
    }
}

struct SwiftUIShareView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIShareView()
    }
}
