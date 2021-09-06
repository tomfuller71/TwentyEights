//
//  PartnerGroup.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/13/21.
//

import Foundation

/// Enum of the partner Groups
enum Team: String, CaseIterable {
   case player = "My Team", opponent = "Opponent"
}

extension Team: Identifiable {
    var id: String { rawValue }
    
    var opposingTeam: Team {
        switch self {
            case .player:   return .opponent
            case .opponent: return .player
        }
    }
    
    var teamMembers: [Seat] {
        switch self {
        case .player:
            return [.north, .south]
        case .opponent:
            return [.east, .west]
        }
    }
}
