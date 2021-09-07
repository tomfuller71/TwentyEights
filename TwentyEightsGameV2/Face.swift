//
//  Face.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

/*
 Enum of a "Face" of a card - commonly know as its rank - however in the game of 28s the rank of cards is unlike most standard card games, order being high to low J,9,A,10,K,Q,8,7.
 Therefore used "rank" as computed prop and "Face" as the normal card rank.
 Also in card of 28s each card has a certain number of points for scoring purposes
 */

enum Face: String, CaseIterable {
    case jack = "J", nine = "9", ace = "A", ten = "10", king = "K", queen = "Q", eight = "8", seven = "7"
}

extension Face {
    var rank: Int {
        switch self {
        case .jack:     return 7
        case .nine:     return 6
        case .ace:      return 5
        case .ten:      return 4
        case .king:     return 3
        case .queen:    return 2
        case .eight:    return 1
        case .seven:    return 0
        }
    }
    
    /// Points scored in game of 28s for each card
    var points: Int {
        switch self {
        case .jack:     return 3
        case .nine:     return 2
        case .ace,.ten: return 1
        default:        return 0
        }
    }
    /// Index of the card face
    var index: Int {
        switch self {
        case .ace:      return 0
        case .jack:     return 10
        case .queen:    return 11
        case .king:     return 12
            
        default:
            return (Int(self.rawValue)! - 1)
        }
    }
}


