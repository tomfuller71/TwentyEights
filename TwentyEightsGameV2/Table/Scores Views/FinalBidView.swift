//
//  FinalBidView.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import SwiftUI

/// View that shows who is the bidder, the points bid and if revealed the trump suit
struct FinalBidView: View {
    var bid: UserView.ScoresViewModel.BidStatus
    
    @Environment(\.cardValues) var cardValues
   // var fontSize: CGFloat { cardSize.height * _28s.fontCardHeightScale }
    
    var body: some View {
        VStack(spacing: 3) {
            
            //Show who is the bidding team and the current bid
            HStack {
                Image(systemName: "chevron.backward.square.fill")
                    .font(.custom("system", fixedSize: cardValues.fontSize))
                    .opacity(bid.bidIndicator == .left ? 1 : 0)
                
                Text("Bid \(bid.bidPoints)")
                    .allowsTightening(true)
                    .opacity(bid.bidPoints > 0 ? 1 : 0)
                
                Image(systemName: "chevron.forward.square.fill")
                    .font(.custom("system", fixedSize: cardValues.fontSize))
                    .opacity((bid.bidIndicator == .right) ? 1 : 0)
            }
            
            // If trump called show the trump suit
            HStack(spacing: nil) {
                if let suit = bid.trumpSuit, bid.trumpCalled {
                    Text("Trump:")
                    Text(suit.rawValue)
                        .font(.custom("system", fixedSize: cardValues.fontSize))
                        .foregroundColor(suit.suitColor)
                }
                else {
                    Text("Placeholder")
                        .opacity(0)
                }
            }
        }
        .font(.copperPlate, size: cardValues.fontSize)
    }
}

struct FinalBidView_Previews: PreviewProvider {
    static var previews: some View {
        let bids = [
            UserView.ScoresViewModel.BidStatus(
                bidPoints: 14,
                trumpCalled: true,
                trumpSuit: .heart,
                bidIndicator: .right
            ),
            
            UserView.ScoresViewModel.BidStatus(
                bidPoints: 14,
                trumpCalled: false,
                trumpSuit: nil,
                bidIndicator: nil
            ),
            
            UserView.ScoresViewModel.BidStatus(
                bidPoints: 21,
                trumpCalled: false,
                trumpSuit: .spade,
                bidIndicator: .left
            )
        ]
        
        ZStack {
            BackgroundView()
            
            VStack(spacing: 15) {
                ForEach(bids, id: \.self) { bid in
                    Divider().frame(height: 0.5).background(Color.offWhite)
                    FinalBidView(bid: bid)
                }
            }
            .foregroundColor(.offWhite)
            .previewFor28sWith(.iPhone8)
        }
    }
}
