//
//  CardPositionData.swift
//  TwentyEights
//
//  Created by Tom Fuller on 10/11/20.
//

import SwiftUI

// Flashes are the "pips" on a playing card
/// The position and inversion of an individual flash on a playing card
struct CardFlashPosition: Hashable {
    var xOffset: CGFloat
    var yOffset: CGFloat
    var inverted: Bool
}
/// Provides the data of  card flash positions for use in CardInsertView
struct CardFlashes {
    /// Gets the flash position data for a given card
    static func getFlashes(for card: Card) -> [CardFlashPosition] {
        return flashData[card.face.index]
    }
    // Data of card flash positions for each card face
   private static var flashData: [[CardFlashPosition]] = [
        [CardFlashPosition(xOffset: 0.5, yOffset: 0.5, inverted: false)], // ace
        
        [CardFlashPosition(xOffset: 0.5, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 1.0, inverted: true)], // two
        
        [CardFlashPosition(xOffset: 0.5, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 1.0, inverted: true)], // three
        
        [CardFlashPosition(xOffset: 0.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 1.0, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 1.0, inverted: true)], //four
        
        [CardFlashPosition(xOffset: 0.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 1.0, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 1.0, inverted: true)], //five
        
        [CardFlashPosition(xOffset: 0.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 1.0, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 1.0, inverted: true)], //six
        
        [CardFlashPosition(xOffset: 0.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.25, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 1.0, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 1.0, inverted: true)], //seven
        
        [CardFlashPosition(xOffset: 0.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.25, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.75, inverted: true),
         CardFlashPosition(xOffset: 0.0, yOffset: 1.0, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 1.0, inverted: true)], //eight
        
        [CardFlashPosition(xOffset: 0.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 0.33, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.33, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.5, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 0.66, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.66, inverted: true),
         CardFlashPosition(xOffset: 0.0, yOffset: 1.0, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 1.0, inverted: true)], //nine
        
        [CardFlashPosition(xOffset: 0.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.0, inverted: false),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.166, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 0.33, inverted: false),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.33, inverted: false),
         CardFlashPosition(xOffset: 0.0, yOffset: 0.66, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 0.66, inverted: true),
         CardFlashPosition(xOffset: 0.5, yOffset: 0.83, inverted: true),
         CardFlashPosition(xOffset: 0.0, yOffset: 1.0, inverted: true),
         CardFlashPosition(xOffset: 1.0, yOffset: 1.0, inverted: true)], //ten
        
        [CardFlashPosition(xOffset: 0.5, yOffset: 0.5, inverted: false)], // jack
        
        [CardFlashPosition(xOffset: 0.5, yOffset: 0.5, inverted: false)], // queen
        
        [CardFlashPosition(xOffset: 0.5, yOffset: 0.5, inverted: false)], // king
    ]
}

