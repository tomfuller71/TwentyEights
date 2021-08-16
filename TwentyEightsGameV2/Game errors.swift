//
//  Game errors.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 8/14/21.
//

import Foundation


enum GameError: Error {
    case incorrectActionType(PlayerAction.ActionType)
    case error
}
