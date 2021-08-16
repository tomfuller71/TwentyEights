//
//  NestedStructs.swift
//  JokerGame
//
//  Created by Tom Fuller on 2/22/21.
//

import Foundation

extension CPUPlayer {
    
    /// The expected points for a card of that suit played by a subsequent PartnerGroup under the assumption that they are playing to win the trick and under the assumption that they are playing to lose
    struct ExpectedPoints {
        var winning: Double = 0.0
        var losing: Double = 0.0
    }
    
    /// Structure that hold AI player evlaution of  potential  card to play
    struct CardEvaluation {
        var card: Card
        var winChance: Double = 0
        var trickPointValue: (winPoints: Double, losePoints: Double) = (winPoints: 0, losePoints: 0)
        var netExpectedPoints: Double { winChance * trickPointValue.winPoints - (1 - winChance) * trickPointValue.losePoints }
    }
    
    /// The chance that a suit played  will be trumped by a subsequent PartnerGroup,  and the expected points for a card of that suit played by a subsequent PartnerGroup
    struct SuitEvaluation {
        var trumpChance: Double = 0
        var expectedPoints: ExpectedPoints = ExpectedPoints()
    }
    
    /// Struct that hold a dictionary [PartnerGroup : SuitEvalulation] which can init as complete and empty and be subscripted without force unwrapping
    struct TeamsEvaluations {
        var teams: [PartnerGroup : SuitEvaluation] = [.player : SuitEvaluation(), .opponent: SuitEvaluation()]
        subscript(_ team: PartnerGroup) -> SuitEvaluation {
            get {
                teams[team]!
            }
            set(newValue) {
                teams[team]! = newValue
            }
        }
    }
    
    /// Struct that hold a dictionary [Suit : TeamEvaluations] which can init as complete and empty and be subscripted without force unwrapping
    struct BestSuitToPlayAnalysis {
        var suits : [Suit : TeamsEvaluations]
        subscript(_ suit: Suit) -> TeamsEvaluations {
            get {
                suits[suit]!
            }
            set(newValue) {
                suits[suit]! = newValue
            }
        }
        
        init() {
            self.suits = Suit.allCases.reduce(into: [Suit : TeamsEvaluations]()) { (dict, suit) in dict[suit] = TeamsEvaluations() }
        }
    }
    
    
    /// A structure that contains the following seats yet to play in a trick and provides methods to return Sets of Seats yet to play by PartnerGroup, and optionally excluding seats known to be empty of a given suit
    struct Following {
        let seats: Set<Seat>
        let seatsKnownEmptyForSuit: [Suit : Set<Seat>]
        
        init(seats: Set<Seat>, emptySuits: [Suit : Set<Seat>]) {
            self.seats = seats
            self.seatsKnownEmptyForSuit = emptySuits
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
        func seatsofGroup(_ group: PartnerGroup) -> Set<Seat> {
            seats.filter { $0.partnerGroup == group }
        }
        
        /// Returns the seats yet to play  filtered by a partnerGroup and optionally excluding seats known empty of Suit
        func seats_OfGroup_Not_EmptyofSuit(_ group: PartnerGroup, _ suit: Suit?) -> Set<Seat> {
            var following = seats.filter { $0.partnerGroup == group }
            if let suit = suit {
                following = following.subtracting(seatsKnownEmptyForSuit[suit]!)
            }
            return following
        }
        
        func seats_OfGroup_EmptyofSuit(_ group: PartnerGroup, _ suit: Suit?) -> Set<Seat> {
            var following = seats.filter { $0.partnerGroup == group }
            if let suit = suit {
                following = following.intersection(seatsKnownEmptyForSuit[suit]!)
            }
            return following
        }
    }
}
