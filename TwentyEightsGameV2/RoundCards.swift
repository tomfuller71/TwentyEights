//
//  RoundCards.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/2/21.
//

import Foundation

/// Shared round cards instance (just to simplify nested structs)
struct RoundCards {
    private var deal: [Card] = Deck.deck.shuffled()
    var hands: [Seat : Hand] = Seat.allCases.reduce(into: [:]) {$0[$1] = [] }
    
    subscript(_ seat: Seat) -> Hand {
        hands[seat]!
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
    
    mutating func returnTrumpToHand(trump: Card, bidder: Seat) {
        hands[bidder]!.append(trump)
    }
    
    func remainingCardsExcludingSeat(_ seat: Seat) -> [Card] {
        var cards = [Card]()
        for hand in Seat.allCases {
            if hand != seat {
                cards.append(contentsOf: hands[hand]!)
            }
        }
        return cards
    }
}

    


