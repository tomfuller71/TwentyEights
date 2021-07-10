//
//  SwiftUIView.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/6/21.
//

import SwiftUI

struct SeatView: View {
    let seats: UserView.SeatSelectionViewModel
    let cardSize: CGSize
    
    var body: some View {
        ZStack {
            SeatPlaceHoldersView(cardSize: cardSize)
            SeatSelectionsView(selections: seats.selections, highlightSeat: seats.highlightSeat, cardSize: cardSize)
            ActiveSeatIndictorView(indicatorAngle: seats.indicatorAngle, size: cardSize.height * 0.01)
        }
    }
}

struct SeatView_Previews: PreviewProvider {
    static var previews: some View {
        let selections = [
            PlayerAction(seat: .south, type: .playCardInTrick(Card(face: .ace, suit: .heart))),
            PlayerAction(seat: .north, type: .playCardInTrick(Card(face: .jack, suit: .heart))),
            PlayerAction(seat: .east, type: .pass(stage: .first)),
            PlayerAction(seat: .west, type: .makeBid(
                            Bid(points: 16, card: Card(face: .ten, suit: .club), stage: .first))
            )
        ]
        
        let model = UserView.SeatSelectionViewModel(
            selections: selections, highlightSeat: .none, indicatorAngle: Angle(degrees: Seat.south.angle))
        
        ZStack {
            BackgroundView()
            SeatView(seats: model, cardSize: _28s.cardSize_screenHeight_667)
        }
    }
}

