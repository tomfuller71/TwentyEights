//
//  Suit.swift
//  TwentyEights
//
//  Created by Tom Fuller on 10/12/20.
//

import SwiftUI

/// Enumeration of the suits in a deck of playing cards with rawValue of string literal of the corresponding suit icon
enum Suit: String, CaseIterable {
    case  club = "♣︎", diamond = "♦︎", heart = "♥︎", spade = "♠︎"
}

extension Suit {
    /// Custom sort the way the cards appear left to right in a CardhandView
    var orderInHand: Int {
        switch self {
        case .club:     return 0
        case .diamond:  return 1
        case .spade:    return 2
        case .heart:    return 3
        }
    }
    
    // Used in the CardView
    var suitColor: Color {
        switch self {
        case .heart, .diamond:
            return Color(.red)
            
        case .club, .spade:
            return Color(.black)
        }
    }
}
