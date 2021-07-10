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
    var played: [(seat: Seat, card: Card)] = []
    var winningSeat: Seat?
    var winningRank: Int = 0
}

// MARK:- Trick state
extension Trick {
    // Computed properties
    var isEmpty: Bool { played.isEmpty }
    var isComplete: Bool { played.count == 4 }
    var leadSuit: Suit? { played.first?.card.suit }
    var seatToPlay: Seat {
        isEmpty ? starting : ( isComplete ? winningSeat! : played.last!.seat.nextSeat())
    }
    
    var followingSeats: Set<Seat> { self.seatsYetToPlay().subtracting([seatToPlay]) }
    var pointsInTrick: Int { played.reduce(into: 0, { $0 += $1.card.face.points }) }
    
    /// Returns the seats that are yet to play in the trick after the current seat
    func seatsYetToPlay() -> Set<Seat> {
        var seats = Set<Seat>()
        guard !isComplete else { return seats }
        seats = Set(Seat.allCases)
        if !isEmpty {
            seats = seats.subtracting(played.compactMap { $0.seat })
        }
        return seats
    }
    
    /// Returns set of seat following that are members of the given team
    func followingSeatsOfTeam(_ group: PartnerGroup) -> Set<Seat> {
        return followingSeats.filter { $0.partnerGroup == group }
    }
}

// MARK:- Trick model update methods
extension Trick {
    /// Update the current trick with a card
    mutating func updateTrickWith(seat: Seat, card : Card) {
        // If leading out - set the first card as the winner
        if isEmpty {
            winningRank = card.currentRank
            winningSeat = seat
        }
        // If not empty then only update if a lead or trump (and trump called) and current rank is higher
        else if card.currentRank > winningRank {
            winningRank = card.currentRank
            winningSeat = seat
        }
        // Update the cards in the current trick and played cards Array
        played.append((seat: seat, card: card))
    }
}


