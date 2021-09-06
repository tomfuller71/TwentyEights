//
//  Following.swift
//  Following
//
//  Created by Thomas Fuller on 9/2/21.
//

import Foundation

extension CPUPlayer {
    
    /// A structure that contains the following seats yet to play in a trick and provides methods to return Sets of Seats yet to play by PartnerGroup, and optionally excluding seats known to be empty of a given suit
    struct Following {
        let seats: Set<Seat>
        let seatsKnownEmptyForSuit: [Suit : Set<Seat>]
        
        init(seats: Set<Seat>, emptySuits: [Suit : Set<Seat>]) {
            self.seats = seats
            self.seatsKnownEmptyForSuit = emptySuits
        }
        
        
        /// Returns number of players in each team yet to play in the current trick
        func getTeamCounts() -> [Team : Int ] {
            [.player : seatsOfTeam(.player).count,
             .opponent: seatsOfTeam(.opponent).count
            ]
        }
        
        var teamsYetToPlay: Set<Team> {
            seats.reduce(into: Set<Team>()) { set, seat in
                set.insert(seat.team)
            }
        }
        
        /// Returns the seats yet to play  optionally excluding seats known empty of Suit
        func seatsNotEmptyof(_ suit: Suit?) -> Set<Seat> {
            var following = seats
            if let suit = suit {
                following = following.subtracting(seatsKnownEmptyForSuit[suit]!)
            }
            return following
        }
        
        /// Returns the seats yet to play  optionally excluding seats known empty of Suit
        func seatsOfTeam(_ group: Team) -> Set<Seat> {
            seats.filter { $0.team == group }
        }
        
        /// Returns the seats yet to play  filtered by a partnerGroup and optionally excluding seats known empty of Suit
        func seats_OfGroup_Not_EmptyofSuit(_ group: Team, _ suit: Suit?) -> Set<Seat> {
            var following = seats.filter { $0.team == group }
            if let suit = suit {
                following = following.subtracting(seatsKnownEmptyForSuit[suit]!)
            }
            return following
        }
        
        func seats_OfGroup_EmptyofSuit(_ group: Team, _ suit: Suit?) -> Set<Seat> {
            var following = seats.filter { $0.team == group }
            if let suit = suit {
                following = following.intersection(seatsKnownEmptyForSuit[suit]!)
            }
            return following
        }
    }
    
    /// Returns seats in a team from a Seat.SetType with default value of only seats that follow player in the current trick
    func seatsOfTeam(_ team: Team, from setType: Seat.SetType = .following) -> Set<Seat> {
        game.round.getSetofSeats(type: setType).filter { $0.team == team }
    }
    
    /// Returns number of players in each team following the player  in the current trick
    func getTeamCounts() -> [Team : Int ] {
        [.player : seatsOfTeam(.player).count,
         .opponent: seatsOfTeam(.opponent).count
        ]
    }
    
    /// Returns  which seats are not known to be empty of the given suit from a Seat.SetType defaulted to all seats
    func seatsNotKnownEmptyOf(_ suit: Suit, from setType: Seat.SetType = .all) -> Set<Seat> {
        game.round.getSetofSeats(type: setType)
            .subtracting(game.round.seatsKnownEmptyForSuit[suit]!)
    }
    
    /// Returns  which seats are not known to be empty of the given suit from a Seat.SetType defaulted to all seats
    func seatsEmpty(of suit: Suit, from setType: Seat.SetType = .all) -> Set<Seat> {
        game.round.getSetofSeats(type: setType)
            .intersection(game.round.seatsKnownEmptyForSuit[suit]!)
    }
    
    /// Returns the follow seats not known to be empty of the given suit from the provided team
    func followingNotEmpty(of suit: Suit, from team: Team) -> Set<Seat> {
        return seatsNotKnownEmptyOf(suit, from: .following).filter { $0.team == team }
    }
    
    /// Returns the follow seats known to be empty of the given suit from the provided team
    func followingEmpty(of suit: Suit, from team: Team) -> Set<Seat> {
        return seatsEmpty(of: suit, from: .following).filter { $0.team == team }
    }
    
    
    
    
}
