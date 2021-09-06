//
//  CPU Player + OtherHandCards.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 8/26/21.
//

import Foundation

extension CPUPlayer {
    /// Structure that holds an analysis of the cards in other players Hands
    struct OtherHandsAnalysis {
        var cards: [Card] = []
        var hiddenTrump: Card?
        var suits: [Suit : SuitAnalysis] = [:]
        var seatHasHiddenTrump: Bool { hiddenTrump != nil }
        var population: Int { cards.count }
        
        init(seat: Seat, cards: [Card], trump: Trump) {
            var allCards = cards
            // If not the bidder then cpuPlayer has to assume trump is in a hand
            if let card = trump.card, !trump.isCalled && trump.bidder != seat {
                allCards.append(card)
            }
            
            self.cards = allCards
            
            //Inits suits analysis dictionary
            var remaining: [Suit : SuitAnalysis] = Suit.allCases.reduce(into:[:]) {
                $0[$1] = SuitAnalysis() }
            
            for card in allCards {
                remaining[card.suit]!.cards.append(card)
                remaining[card.suit]!.count += 1
                
                if card.face.points > 0 {
                    remaining[card.suit]!.honorPoints += card.face.points
                    remaining[card.suit]!.honorCards.append(card)
                }
                
                if (card.currentRank > remaining[card.suit]!.topRank) {
                    remaining[card.suit]!.topRank = card.currentRank
                }
            }
            
            // If player the bidder they are aware of the hidden trump
            if !trump.isCalled && trump.bidder == seat {
                hiddenTrump = trump.card!
                remaining[trump.suit!]!.hiddenTrump = trump.card!
            }
            
            self.suits = remaining
        }
    }
    /// Structure holding analysis of the suited cards in other players hands
    struct SuitAnalysis {
        var cards: [Card] = []
        var count: Int = 0
        var topRank: Int = 0
        var honorCards: [Card] = []
        var honorPoints: Int = 0
        var hiddenTrump: Card?
    }
}
