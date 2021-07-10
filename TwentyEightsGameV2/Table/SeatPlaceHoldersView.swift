//
//  SeatPlaceHoldersView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct SeatPlaceHoldersView: View {
    let cardSize: CGSize
    
    var body: some View {
        GeometryReader { proxy in
            ForEach(Seat.allCases, id: \.self) { seat in
                CardPlaceHolderView(cardSize: cardSize)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .position(
                        x: proxy.center.x + (seat.offsetPoint.x * cardSize.width),
                        y: proxy.center.y + (seat.offsetPoint.y * cardSize.height)
                )
            }
        }
    }
}

struct SeatPlaceHoldersView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            SeatPlaceHoldersView(cardSize: _28s.cardSize_screenHeight_667)
        }
    }
}
