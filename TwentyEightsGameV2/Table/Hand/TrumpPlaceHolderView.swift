//
//  TrumpPlaceHolderView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct TrumpPlaceHolderView: View {
    var cardSize: CGSize
    
    var body: some View {
        ZStack{
            CardPlaceHolderView(cardSize: cardSize)
            Text("TRUMP")
                .tracking(trackingScale) // just widening the font a tad
                .baselineOffset(offsetScale) // the engraved font default placement is top aligned
                .font(Font.custom("Academy Engraved LET", fixedSize: textScale).bold())
                .rotationEffect(.degrees(textRotation))
                .foregroundColor(.lemon)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }
    
    private var textScale: CGFloat { 0.2 * cardSize.width }
    private var trackingScale: CGFloat { 0.04 * cardSize.width }
    private var offsetScale: CGFloat { -0.08 * cardSize.width }
    private let textRotation: Double = -60
}

struct TrumpPlaceHolderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            TrumpPlaceHolderView(cardSize: _28s.cardSize_screenHeight_667)
        }
    }
}
