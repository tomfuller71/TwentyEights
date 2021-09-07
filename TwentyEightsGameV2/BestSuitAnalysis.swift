//
//  BestSuitAnalysis.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import Foundation

extension CPUPlayer {
    /// Struct that hold a dictionary [Suit : TeamEvaluations] which can init as complete and empty and be subscripted without force unwrapping
    struct BestSuitToPlayAnalysis {
        var suits : [Suit : TeamsEvaluations]
        subscript(_ suit: Suit) -> TeamsEvaluations {
            get {
                suits[suit]!
            }
            set(newValue) {
                suits[suit]! = newValue
            }
        }
        
        init() {
            self.suits = Suit.allCases.reduce(into: [Suit : TeamsEvaluations]()) {
                (dict, suit) in dict[suit] = TeamsEvaluations()
            }
        }
    }
    
    /// Struct that hold a dictionary [PartnerGroup : SuitEvalulation] which can init as complete and empty and be subscripted without force unwrapping
    struct TeamsEvaluations {
        var teams: [Team : CutAndExpectedPoints] = [
            .player : CutAndExpectedPoints(),
            .opponent: CutAndExpectedPoints()
        ]
        
        subscript(_ team: Team) -> CutAndExpectedPoints {
            get {
                teams[team]!
            }
            set(newValue) {
                teams[team]! = newValue
            }
        }
    }
    
    /// The chance that a suit played will be trumped by a subsequent PartnerGroup,  and the expected points for a card of that suit played by a subsequent PartnerGroup
    struct CutAndExpectedPoints {
        var trumpChance: Double = 0
        var expectedPoints: ExpectedPoints = ExpectedPoints()
    }
    
}
