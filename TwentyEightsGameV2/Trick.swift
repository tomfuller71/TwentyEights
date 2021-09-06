//
//  Trick.swift
//  TwentyEights
//
//  Created by Tom Fuller on 12/2/20.
//
import SwiftUI

/// Structure representing one trick being played during the playingRound stage of 28s
struct Trick {
    var starting: Seat
    var seatActions: [PlayerAction] = []
    var leadSuit: Suit?
    var winningSeat: Seat?
    var winningRank: Int = 0
    var lastSeatPlayed: Seat?
    var seatsYetToPlay: Set<Seat> = Set(Seat.allCases)
    var pointsInTrick: Int = 0
}

//MARK:- Trick update method and computed properties
extension Trick {
    var isEmpty: Bool { seatActions.isEmpty }
    var playerIsLastToPlay: Bool { seatActions.count == 3 }
    var isComplete: Bool { seatActions.count == 4 }
    
    /// The seat that is due to play a card next in the round
    var seatToPlay: Seat {
        if isEmpty {
           return starting
        }
        else if isComplete {
            return winningSeat!
        }
        else {
            return lastSeatPlayed!.nextSeat()
        }
    }
    
    /// The seats that follow after the current player in the trick
    var followingSeats: Set<Seat> {
        seatsYetToPlay.subtracting([seatToPlay])
    }
    
    /// Returns set of seat following that are members of the given team
    func followingSeatsOfTeam(_ group: Team) -> Set<Seat> {
        return followingSeats.filter { $0.team == group }
    }
    
    /// Updates the current trick with the player action with knowledge of whether the card played is trump
    mutating func updateTrickWithAction(action: PlayerAction, isTrump: Bool) {
        guard case .playCardInTrick(let card) = action.type else {
            print("Error - Invalid action type received")
            return
        }
        
        lastSeatPlayed = action.seat
        seatsYetToPlay.subtract([action.seat])
        pointsInTrick += card.face.points
        
        if isEmpty {
            leadSuit = card.suit
        }
        
        if isEmpty || ( (card.suit == leadSuit || isTrump) && card.currentRank > winningRank ) {
            winningRank = card.currentRank
            winningSeat = action.seat
        }
        
        seatActions.append(action)
    }
}


