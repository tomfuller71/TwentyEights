//
//  GameStage.swift
//  TwentyEights
//
//  Created by Tom Fuller on 12/7/20.
//


enum GameStage: Equatable {
    case playingRound(Round.RoundStage), endingGame
}
