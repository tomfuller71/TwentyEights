//
//  Deck.swift
//  TwentyEights
//
//  Created by Tom Fuller on 10/12/20.
//

/// Structure that hold a deck of cards used in game of 28s and method to shuffe and deal
struct Deck {
    
    // Make a deck of cards
    static let deck: [Card] = {
        var newDeck: [Card] = []
        
        for suit in Suit.allCases {
            for face in Face.allCases {
                newDeck.append(Card(face: face, suit: suit))
            }
        }
        return newDeck
    }()
}

    



