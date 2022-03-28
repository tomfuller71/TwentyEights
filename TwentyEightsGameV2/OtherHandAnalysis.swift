//
//  CPU Player + OtherHandCards.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import Foundation

extension CPUPlayer {
    /// Structure that holds an analysis of the cards in other players Hands
    struct OtherHandsAnalysis {
        var suits: [Suit : SuitAnalysis] = [:]
        var population: Int = 0
        
        /// Returns true no other player has cards of the given suit
        func isEmpty(of suit: Suit) -> Bool {
            suits[suit]!.count == 0
        }
        
    }
    /// Structure holding analysis of the suited cards in other players hands
    struct SuitAnalysis {
        var count: Int = 0
        var topRank: Int = 0
        var honorCards: [Card] = []
        var honorPoints: Int = 0
    }
}
