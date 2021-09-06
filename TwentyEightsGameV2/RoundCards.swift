//
//  RoundCards.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/2/21.
//

import Foundation

/// Shared round cards instance (just to simplify nested structs)
struct RoundCards {
    private var deal: [Card] =  RoundCards.deal()
    var hands: [Seat : Hand] = Seat.allCases.reduce(into: [:]) {$0[$1] = [] }
    
    subscript(_ seat: Seat) -> Hand {
        hands[seat]!
    }
    
    /// Returns the cards in hand (excluding any unrevealed Trump) for all hands other than the given seat
    func remainingCardsExcludingSeat(_ seat: Seat) -> [Card] {
        var cards = [Card]()
        for hand in Seat.allCases {
            if hand != seat {
                cards.append(contentsOf: hands[hand]!)
            }
        }
        return cards
    }
    
    
    /// Returns true if the given seat has only one card in hand which is an honor card
    func honorPointCardsFor(seat: Seat, suit: Suit) -> [Card] {
        hands[seat]!.filter { $0.suit == suit && $0.face.points > 0 }
    }
    
    /// Returns true if the hand of given seat has only one sole (shake) honor card of the given suit
    func hasSoleHonorCard(seat: Seat, suit: Suit) -> Bool {
        hands[seat]!.filter { $0.suit == suit }.count == honorPointCardsFor(seat: seat, suit: suit).count
    }
    
    /// Returns a shuffled deck of the 28 cards used in game of 28s
    static func deal() -> [Card] {
        var newDeck: [Card] = []
        
        for suit in Suit.allCases {
            for face in Face.allCases {
                newDeck.append(Card(face: face, suit: suit))
            }
        }
        return newDeck.shuffled()
    }
}
 
//MARK: - Public Mutating methods
extension RoundCards {
    /// Add 4 cards to each hand (once at start of bidding and then once again  on second bidding stage)
    mutating func add4CardsToHands() {
        for seat in Seat.allCases {
            let deal4: [Card] = Array(deal.prefix(4))
            deal.removeFirst(4)
            hands[seat]! += deal4
        }
    }
    
    /// Removes the provided cards from the given seat
    mutating func removeCardFromSeat(_ card: Card, seat: Seat) {
        
        let index: Int? = hands[seat]!.firstIndex(of: card)
        if let index = index {
            hands[seat]!.remove(at: index)
        }
        else {
            fatalError("Error - card was unexpectedly not in Hand")
        }
    }
    
    /// Updates the current rank for all cards of the trump suit
    mutating func updateTrumpCardRank(trumpSuit: Suit) {
        for seat in Seat.allCases {
            for i in 0 ..< hands[seat]!.count {
                if hands[seat]![i].suit == trumpSuit {
                    hands[seat]![i].currentRank += _28s.initalHandSize
                }
            }
        }
    }
    
    /// Returns the provided trump card to the given bidder
    mutating func returnTrumpToHand(trump: Card, bidder: Seat) {
        hands[bidder]!.append(trump)
    }

}

    


