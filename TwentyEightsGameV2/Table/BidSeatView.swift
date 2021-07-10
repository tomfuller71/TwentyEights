//
//  BidView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/18/21.
//

import SwiftUI

struct BidSeatView: View {
    let points: Int?
    let cardSize: CGSize
    var bidText: String { points != nil ? "Bid" : "Pass" }
    
    var body: some View {
        VStack {
            Text("\(bidText)")
                .baselineOffset(-3)
            
            if let points = points {
                Text("\(points)")
                    .baselineOffset(-3)
            }
        }
        .foregroundColor(.offWhite)
        .font(Font.custom("Academy Engraved LET", fixedSize: cardSize.width * 0.25))
    }
}

struct BidView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            BidSeatView(points: 14, cardSize: _28s.cardSize_screenHeight_667)
        }
    }
}
