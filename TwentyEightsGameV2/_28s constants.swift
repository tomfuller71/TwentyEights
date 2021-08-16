//
//  _28s constants.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/2/21.
//

import Foundation
import SwiftUI

enum _28s {
    /// The standard delay in seconds between a UI updating player initiated action
    static let uiDelay: Double = 1.5
    
    /// The initial points that a team in a game of 28s start with.  If the team reaches zero point they lose.
    static let gameTeamStartingPoints: Int = 0
    
    /// The sum of the " honor point" value of each card within the initial deck of cards used in  a game of 28s.  Where the name 28s comes from!
    static let pointsInDeck: Int = 28
    
    
    /// The initial handSize of a hand
    static let initalHandSize = 8
    
    
    /// Card UI constants
    static let card = CardConstants()
    struct CardConstants {
        let strokeColor = Color.cayenne
        let strokeRatio: CGFloat = 0.015
        let cornerRadiusRatio: CGFloat = 0.1
        let aspect = CGSize(width: 0.643, height: 1)
    }
    
    static let standardCard = CGSize(width: 2.25, height: 3.5)
    static let standardCardWidthRatio = CGFloat(standardCard.width / standardCard.height)
    
    /// User only in previews
    static let cardSize_screenHeight_667 = CGSize(width: 667 * 0.2 * standardCardWidthRatio, height: 667 * 0.2)
    
    /// The points team will gain if they win their bid, or if they lose they lose this + 1
    static func gamePointsForBidOf(_ bid: Int) -> Int {
        switch bid {
        case 0..<20:
            return 1
        case 20..<25:
            return 2
        default:
            return 3
        }
    }
    
    /// Static default values for players in non-multiplayer Game
    static let players: [Seat : Player] = [
         .south : Player(name: "South",playerType: .localUser),
         .north : Player(name: "North", playerType: .localCPU),
         .east : Player(name: "East", playerType: .localCPU),
         .west : Player(name: "West", playerType: .localCPU),
     ]
    
    
    /// Static property of the arbitary value given to each card of the same suit above a set level
    static let bidPointsPerExtraCard: Double = 2.0

    /// The number of cards of a given suit  that must be exceeded for the bid point calculation to factor in extra points
    static let extraCardofSuitLimit: Int = 2
    
    /// The minimum number of points above the minBid needed for CPU player to bid
    static let minBidBufffer: Int = 1
}

