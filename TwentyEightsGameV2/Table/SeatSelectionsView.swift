//
//  SeatSelectionsView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct SeatSelectionsView: View {
    var selections: [PlayerAction]
    var highlightSeat: Seat?
    var cardSize: CGSize
    
    var body: some View {
        GeometryReader { proxy in
            ForEach(selections) {  selection in
                Group {
                    if case .playCardInTrick(let card) = selection.type {
                        CardView(card: card)
                            .glow(color: (highlightSeat == selection.seat ? Color.lemon : Color.clear))
                    }
                    else if case .makeBid(let bid) = selection.type {
                        BidSeatView(points: bid.points, cardSize: cardSize)
                    }
                    else {
                        BidSeatView(points: nil, cardSize: cardSize)
                    }
                }
                .frame(width: cardSize.width, height: cardSize.height)
                .position(
                    x: proxy.center.x + (selection.seat.offsetPoint.x * cardSize.width),
                    y: proxy.center.y + (selection.seat.offsetPoint.y * cardSize.height)
                )
            }
        }
    }
}

struct SeatSelectionsView_Previews: PreviewProvider {
    static var previews: some View {
        let selections = [
            PlayerAction(seat: .south, type: .playCardInTrick(Card(face: .ace, suit: .heart))),
            PlayerAction(seat: .north, type: .playCardInTrick(Card(face: .jack, suit: .heart))),
            PlayerAction(seat: .east, type: .pass(stage: .first)),
            PlayerAction(seat: .west, type: .makeBid(Bid(points: 16, card: Card(face: .ten, suit: .club), stage: .first)))
        ]
        
        ZStack {
            BackgroundView()
            SeatSelectionsView(
                selections: selections,
                highlightSeat: .north,
                cardSize: _28s.cardSize_screenHeight_667
            )
        }
    }
}
