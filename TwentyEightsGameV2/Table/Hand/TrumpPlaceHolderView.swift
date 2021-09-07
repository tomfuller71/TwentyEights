//
//  TrumpPlaceHolderView.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import SwiftUI

struct TrumpPlaceHolderView: View {
    @Environment(\.cardValues) var cardValues
    
    var body: some View {
        ZStack{
            CardPlaceHolderView()
            Text("TRUMP")
                .tracking(trackingScale) // just widening the font a tad
                .baselineOffset(offsetScale) // the engraved font default placement is top aligned
                .font(Font.custom("Academy Engraved LET", fixedSize: textScale).bold())
                .rotationEffect(.degrees(textRotation))
                .foregroundColor(.lemon)
        }
        .frame(width: cardValues.size.width, height: cardValues.size.height)
    }
    
    private var textScale: CGFloat { 0.2 * cardValues.size.width }
    private var trackingScale: CGFloat { 0.04 * cardValues.size.width }
    private var offsetScale: CGFloat { -0.08 * cardValues.size.width }
    private let textRotation: Double = -60
}

struct TrumpPlaceHolderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundView()
                TrumpPlaceHolderView()
            }
            .previewFor28sWith(.iPhone8)
            
            ZStack {
                BackgroundView()
                TrumpPlaceHolderView()
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}
