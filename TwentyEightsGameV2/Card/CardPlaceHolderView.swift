//
//  CardPlaceHolderView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct CardPlaceHolderView: View {
    let cardSize: CGSize
    
    var body: some View {
        RoundedRectangle(cornerRadius: cardSize.width * _28s.card.cornerRadiusRatio)
            .strokeBorder(Color.lemon, lineWidth: cardSize.width * _28s.card.strokeRatio * 2)
            .opacity(0.8)
            .frame(width: cardSize.width, height: cardSize.height)
    }
}

struct CardPlaceHolderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            CardPlaceHolderView(cardSize: _28s.cardSize_screenHeight_667)
        }
    }
}
