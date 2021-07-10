//
//  FinalBidView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

/// View that shows who is the bidder, the points bid and if revealed the trump suit
struct FinalBidView: View {
    var bid: UserView.ScoresViewModel.BidStatus
    
    var body: some View {
        VStack(spacing: nil) {
            
            //Show who is the bidding team and the current bid
            HStack(spacing: 17) {
                Image(systemName: "chevron.backward.square.fill")
                    .imageScale(.large)
                    .opacity(bid.bidIndicator == .left ? 1 : 0)
                
                Text("Bid \(bid.bidPoints)")
                    .opacity(bid.bidPoints > 0 ? 1 : 0)
                
                Image(systemName: "chevron.forward.square.fill")
                    .imageScale(.large)
                    .opacity((bid.bidIndicator == .right) ? 1 : 0)
            }
            
            // If trump called show the trump suit
            HStack(spacing: nil) {
                if let suit = bid.trumpSuit, bid.trumpCalled {
                    Text("Trump:")
                    Text(suit.rawValue)
                        .font(.title2)
                        .foregroundColor(suit.suitColor)
                }
                else {
                    Text("Placeholder").font(.title2).opacity(0)
                }
            }
        }
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
            
            .font(.copperPlate)
            .foregroundColor(.offWhite)
        }
    }
}
