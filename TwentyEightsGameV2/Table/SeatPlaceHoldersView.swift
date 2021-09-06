//
//  SeatPlaceHoldersView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct SeatPlaceHoldersView: View {
    @Environment(\.cardValues) var cardValues
    
    var body: some View {
        GeometryReader { proxy in
            ForEach(Seat.allCases, id: \.self) { seat in
                CardPlaceHolderView()
                    .frame(width: cardValues.size.width, height: cardValues.size.height)
                    .position(
                        x: proxy.center.x + (seat.offsetPoint.x * cardValues.size.width),
                        y: proxy.center.y + (seat.offsetPoint.y * cardValues.size.height)
                )
            }
        }
    }
}

struct SeatPlaceHoldersView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            SeatPlaceHoldersView()
                
        }
        .previewFor28sWith(.iPhone8)
    }
}
