//
//  CardEvaluation.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import Foundation

extension CPUPlayer {
    /// Structure that hold for a given card the win chance, expected points in a complete trick if team winning or losing and net expected points value
    struct CardEvaluation {
        var card: Card
        var winChance: Double = 0
        var trickPointValue: (winPoints: Double, losePoints: Double) = (winPoints: 0, losePoints: 0)
        var netExpectedPoints: Double {
            winChance * trickPointValue.winPoints - (1 - winChance) * trickPointValue.losePoints
        }
    }
}
