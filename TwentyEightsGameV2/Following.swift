//
//  CPUPLayer + Following.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import Foundation

// Holds the various CPU methods that are used to calc who is playing next in the current trick
// and whether the seats are known to empty of a given suit or not
extension CPUPlayer {
    
    /// Returns seats in a team from a Seat.SetType with default value of only seats that follow player in the current trick
    func seatsOfTeam(_ team: Team, from setType: Seat.SetType = .following) -> Set<Seat> {
        game.round.getSetofSeats(type: setType).filter { $0.team == team }
    }
    
    /// Returns the teams that follow the current player in the trick 
    func followingTeams() -> Set<Team> {
        game.round.getSetofSeats(type: .following).reduce(into: Set<Team>()) { result, seat in
            result.insert(seat.team)
        }
    }
    
    /// Returns  which seats are not known to be empty of the given suit from a Seat.SetType defaulted to all seats
    func seatsNotEmpty(of suit: Suit, from setType: Seat.SetType = .all) -> Set<Seat> {
        game.round.getSetofSeats(type: setType)
            .subtracting(game.round.seatsKnownEmptyForSuit[suit]!)
    }
    
    /// Returns the follow seats not known to be empty of the given suit from the provided team
    func followingNotEmpty(of suit: Suit, from team: Team) -> Set<Seat> {
        return seatsNotEmpty(of: suit, from: .following).filter { $0.team == team }
    }
    
    /// Returns the follow seats known to be empty of the given suit from the provided team
    func followingEmpty(of suit: Suit, from team: Team) -> Set<Seat> {
        return seatsEmpty(of: suit, from: .following).filter { $0.team == team }
    }
    
    /// Returns  which seats are not known to be empty of the given suit from a Seat.SetType defaulted to all seats
    func seatsEmpty(of suit: Suit, from setType: Seat.SetType = .all) -> Set<Seat> {
        game.round.getSetofSeats(type: setType)
            .intersection(game.round.seatsKnownEmptyForSuit[suit]!)
    }
}
