//
//  GameStage.swift
//  TwentyEights
//
//  Created by Tom Fuller
//


enum GameStage: Equatable {
    case playingRound(Round.RoundStage), endingGame
    
    var textDescription: String {
        switch self {
        case .playingRound(let roundStage):
            return "Playing the round - \(roundStage.textDescription)"

        case .endingGame:
            return "Ending game"
        }
    }
}
