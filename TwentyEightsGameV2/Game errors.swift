//
//  Game errors.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller
//

import Foundation


enum GameError: Error {
    case incorrectActionType(PlayerAction.ActionType)
    case error
}
