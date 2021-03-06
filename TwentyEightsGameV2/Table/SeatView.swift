//
//  SwiftUIView.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import SwiftUI

struct SeatView: View {
    let seats: UserView.SeatSelectionViewModel
    
    
    var body: some View {
        ZStack {
            SeatPlaceHoldersView()
            SeatSelectionsView(selections: seats.selections, highlightSeat: seats.highlightSeat)
            ActiveSeatIndictorView(indicatorAngle: seats.indicatorAngle)
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
                Bid(
                    points: 16,
                    card: Card(face: .ten, suit: .club),
                    bidder: .west
                )
            )
            )
        ]
        
        let model = UserView.SeatSelectionViewModel(
            selections: selections, highlightSeat: .none, indicatorAngle: Angle(degrees: Seat.south.angle))
        
        ZStack {
            BackgroundView()
            SeatView(seats: model)
        }
        .previewFor28sWith(.iPad)
    }
}

