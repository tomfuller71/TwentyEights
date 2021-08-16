//
//  GameStage.swift
//  TwentyEights
//
//  Created by Tom Fuller on 12/7/20.
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
