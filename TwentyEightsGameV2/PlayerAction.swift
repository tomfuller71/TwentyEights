//
//  Bid.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/13/21.
//

import Foundation


/// Action taken by a seat
struct PlayerAction: Identifiable {
    @IntID var id: Int
    var seat: Seat
    var type: ActionType
    
    enum ActionType {
        case startRound
        case selectATrump(Card)
        case unSelectATrump
        case pass(stage: Bidding.BiddingStage)
        case makeBid(_ bid: Bid)
        case startTrick
        case playCardInTrick(Card)
        case callForTrump
        case startNewRound
        case startNewGame
    }
    
    var text: String {
        switch self.type {
        case .startRound:
            return "\(seat.name) started Round"
        case .selectATrump(let card):
            return "\(seat.name) selected \(card.text) as trump"
        case .unSelectATrump:
            return "\(seat.name) unselected their trump"
        case .pass(let stage):
            return "\(seat.name) passed in \(stage) round of bidding"
        case .makeBid(let bid):
            return "\(seat.name) bid \(bid.points) with \(bid.card.text) as trump in \(bid.stage) round of bidding"
        case .startTrick:
            return "\(seat.name) started trick"
        case .playCardInTrick(let card):
            return "\(seat.name) played \(card.text) in trick"
        case .callForTrump:
            return "\(seat.name) called for trump"
        case .startNewRound:
            return "\(seat.name) started new round"
        case .startNewGame:
            return "\(seat.name) started new game"
        }
    }
}

extension PlayerAction.ActionType: Equatable {
    
}

