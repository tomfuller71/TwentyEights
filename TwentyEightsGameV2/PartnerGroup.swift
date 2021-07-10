//
//  PartnerGroup.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/13/21.
//

import Foundation

/// Enum of the partner Groups
enum PartnerGroup: String, CaseIterable {
   case player = "My Team", opponent = "Opponent"
}

extension PartnerGroup: Identifiable {
    var id: String { rawValue }
    
    var opposingTeam: PartnerGroup {
        switch self {
            case .player:   return .opponent
            case .opponent: return .player
        }
    }
}
