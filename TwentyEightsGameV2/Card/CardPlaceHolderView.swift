//
//  CardPlaceHolderView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct CardPlaceHolderView: View {
    @Environment(\.cardValues) var cardValues
    
    var body: some View {
        RoundedRectangle(cornerRadius: cardValues.size.width * _28s.card.cornerRadiusRatio)
            .strokeBorder(Color.lemon, lineWidth: cardValues.size.width * _28s.card.strokeRatio * 2)
            .opacity(0.8)
            .frame(width: cardValues.size.width, height: cardValues.size.height)
    }
}

struct CardPlaceHolderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            CardPlaceHolderView()
        }
        .previewFor28sWith(.iPhone8)
    }
}
