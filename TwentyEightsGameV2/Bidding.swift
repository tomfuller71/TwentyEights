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
    var passCount: Int = 0
    var bid: Bid?
    var bidder: Seat?
    var advanceStage: Bool { passCount == stage.passesBeforeAdvance }
}

struct Bid: Equatable {
    var points: Int
    var card: Card
    var stage: Bidding.BiddingStage
}

extension Bidding {
    enum BiddingStage: Equatable {
        case first, second
        
        /// The number of successive passes required to either advance to the second stage of bidding or more on to playing stage of the game
        var passesBeforeAdvance: Int {
            self == .first ? 3 : 4
        }

        /// The minimum allowable bid for the bidding stage
        var minimumBid: Int {
            self == .first ? 14 : 24
        }
        
        var maximumBid: Int {
            self == .first ? 20 : 28
        }
    }
}
