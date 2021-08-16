//
//  Bid.swift
//  TwentyEights
//
//  Created by Tom Fuller on 11/9/20.
//

import Foundation

/// Data model of the bidding stage of round of 28s
struct Bidding {
    var stage: BiddingStage = .first
    var winningBid: Bid?
    var actions: [PlayerAction] = []
    
    
    /// The lowest points a seat can bid for the current stage of the game
    func bidMinForSeat(_ seat: Seat) -> Int {
        if stage == .first && winningBid?.bidder == seat.partner {
            return max(stage.maximumBid, (winningBid?.points ?? 0) + 1)
        }
        else {
            return max(stage.minimumBid, (winningBid?.points ?? 0) + 1)
        }
    }
    
    /// Determines whether state of round.bidding object is ready to advance to next stage of round
    func roundStageShouldAdvance() -> Bool {
        let countOf = actions.reduce(into: (passes: 0, bids: 0)) { counts, action in
            switch action.type {
            case .makeBid:
                counts.bids += 1
            case .pass:
                counts.passes += 1
            default:
                break
            }
        }
        // If no bid make in current bidding stage then need 4 passes to advance
        // Otherwise need 3 passes
        if countOf.bids == 0 {
            if countOf.passes == 4 {
                return true
            }
            else {
                return false
            }
        }
        else {
            if countOf.passes == 3 {
                return true
            }
            else {
                return false
            }
        }
    }
    
    /// Updates round.bidding state  with players bidding actions
    mutating func updateWith(_ action: PlayerAction) {
        switch action.type {
        case .makeBid(let bid):
            winningBid = bid
            clearActionsAndPasses()
            
        default:
            break
        }
        
        actions.append(action)
    }
    
    /// Empties the round.bidding objects store of players bidding actions and resets the passCount
    mutating func clearActionsAndPasses() {
        actions = []
    }
}

/// A  points  bid by a player in bidding round
struct Bid: Equatable {
    var points: Int
    var card: Card
    var bidder: Seat
}

/// The stages of bidding representing the first distribution of 4 cards and second distribution of 4 cards
extension Bidding {
    enum BiddingStage: Equatable {
        case first, second

        /// The minimum allowable bid for the bidding stage
        var minimumBid: Int { self == .first ? 14 : 24 }
        /// The maximum allowable bid for the bidding stage
        var maximumBid: Int { self == .first ? 20 : 28 }
    }
}
