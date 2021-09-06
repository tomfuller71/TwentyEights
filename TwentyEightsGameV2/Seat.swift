//
//  PlayerSeat.swift
//  TwentyEights
//
//  Created by Tom Fuller on 10/22/20.
//

import SwiftUI

/// Enumeration  of  four seat position at the table that are occupied by a Player
enum Seat: Int, CaseIterable {
    case north = 0, east, south, west
    
    
    /// Enum of the types of seats sets used in the game
    enum SetType {
        /// All Seats
        case all
        /// Seats that have yet to play in the current trick
        case yetToPlay
        /// Seats that follow after the current player in the trick
        case following
    }
    
    /// previous Seats
    var previousSeat: Seat {
        switch self {
            case .north:   return .west
            case .east:    return .north
            case .south:   return .east
            case .west:    return .south
        }
    }
    
    /// The partner Seat of any seat
    var partner: Seat {
        switch self {
            case .north:    return .south
            case .south:    return .north
            case .east:     return .west
            case .west:     return .east
        }
    }
    
    /// The team (type: parterGroup) that a seat belongs to
    var team: Team {
        return (self == .south || self == .north) ? Team.player: Team.opponent
    }
    
    /// Case Label for seat position
    var name : String {
        switch self {
            case .north:    return "North"
            case .east:     return "East"
            case .south:    return "South"
            case .west:     return "West"
        }
    }
    
    /// Used to calculate the position of a selected card in the PlayedCardView (i.e. 0.2 = 20% of view)
    var offsetPoint: CGPoint {
        switch self {
            case .north:    return CGPoint(x: 0, y: -0.7)
            case .east:     return CGPoint(x: 1.2, y: 0)
            case .west:     return CGPoint(x: -1.2, y: 0)
            case .south:    return CGPoint(x: 0, y: 0.7)
        }
    }
    
    /// Rotation angle of the seat
    var angle: Double {
        switch self {
            case .north:    return 0
            case .east:     return 90
            case .south:    return 180
            case .west:     return 270
        }
    }
    
    /// Helper function to advance a seat to the next player anti-clockwise
    mutating func next() {
        switch self {
            case .north:    return self = .east
            case .east:     return self = .south
            case .south:    return self = .west
            case .west:     return self = .north
        }
    }
    
    /// Helper function that returns a Seat that is the next anti-clockwise table position
    func nextSeat() -> Seat {
        switch self {
            case .north:    return .east
            case .east:     return .south
            case .south:    return .west
            case .west:     return .north
        }
    }
}

