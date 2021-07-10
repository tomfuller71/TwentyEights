//
//  CardModel.swift
//  TwentyEights
//
//  Created by Tom Fuller on 10/10/20.
//

import Foundation

typealias Hand = [Card]

/// A  playing card used in the game
struct Card: Identifiable {
    let id: String
    let face: Face
    let suit: Suit
    var currentRank: Int
    
    init(face: Face, suit: Suit) {
        self.id = String("\(face.rawValue)\(suit.rawValue)")
        self.face = face
        self.suit = suit
        self.currentRank = face.rank
    }
}

extension Card: Equatable {
    static func ==(lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
    
    var text: String { face.rawValue + suit.rawValue }
}



