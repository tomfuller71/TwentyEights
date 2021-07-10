//
//  File.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/2/21.
//

import Foundation

/// Datat model of trump in game of 28s
struct Trump {
    var card: Card?
    var bidder: Seat?
    var isCalled: Bool = false
    var beenPlayed: Bool = false
    
    var suit: Suit? { card?.suit }
}

