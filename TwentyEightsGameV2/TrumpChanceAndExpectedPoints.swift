//
//  SuitEvaluation.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import Foundation


// Holds the structures and methods used by CPUPlayer class to determine the chance any given card
// is trumped or not and the associated expected points in the trick if a card of that suit
// wins or loses

extension CPUPlayer {
    /// Hold the chance card can be cut or trumped for or particular mix of suit and team
    struct CanCutHasTrumpChance {
        var canCut: Double =  0
        var hasTrumps: Double = 0
        var trumpChance: Double {
            canCut * hasTrumps
        }
    }
    
    /// A structure that hold the chances of a card of a suit being trumped and the expected trick point won or lost
    struct TrumpChanceAndExpectedPoints {
        var trumpChance: Double = 0.0
        var expectedPoints = ExpectedPoints()
    }
    
    /// A structure that holds for each suit  a dictionary of a teams 'ChancesAndPoints'
    struct SuitTeamChancesAndPoints {
        var analysis: [Suit: [Team : TrumpChanceAndExpectedPoints]]  = Suit.allCases
            .reduce(into: [:]) { result, suit in
                result[suit] = [
                    .player : TrumpChanceAndExpectedPoints(),
                    .opponent : TrumpChanceAndExpectedPoints()
                ]
            }
        
        subscript(_ suit: Suit) -> [Team : TrumpChanceAndExpectedPoints] {
            get {
                return analysis[suit]!
            }
            set(newValue) {
                analysis[suit]! = newValue
            }
        }
    }

    /// Returns chance that team is empty of given suit
    private func chanceTeamEmptyOfSuit(seat: Seat, suit: Suit, pooledState: Bool) ->  Double {
        var sample: Int = 0
        let population: Int = seatsNotEmpty(of: suit).count * handSize
        
        if pooledState {
            sample = followingNotEmpty(of: suit, from: seat.team).count * handSize
        }
        else {
            sample = !seatKnownEmptyOfSuit(seat, suit) ?  handSize : 0
        }
        
        var chance: Double = 0
        if sample != 0 {
            chance = hyperGeoProb(
                success: 0,
                successPopulation: otherHandsAnalysis.suits[suit]!.count,
                sample: sample,
                population: population
            )
        }
        return chance
    }
    
    /// Returns chance team has trumps given suit being evaluated
    private func chanceTeamHasTrumps(seat: Seat, evalSuit: Suit, pooledState: Bool) ->  Double {
        var successPopulation: Int = 0
        var sample: Int = 0
        var population: Int = 0
        
        if trumpKnown {
            successPopulation = otherHandsAnalysis.suits[trump.suit!]!.count
            population = seatsNotEmpty(of: evalSuit).count * handSize
            if pooledState{
                sample = followingNotEmpty(of: trump.suit!, from: seat.team).count * handSize
            }
            else {
                sample = seatKnownEmptyOfSuit(seat, trump.suit!) ? handSize : 0
            }
        }
        else {
            successPopulation = expectedTrumpCount()
            population = otherHandsAnalysis.population
            sample = pooledState ? seatsOfTeam(seat.team).count * handSize : handSize
        }
        
        var chance: Double = 0
        if sample != 0 && successPopulation != 0 {
            chance = hyperGeoProb(
                success: 0,
                successPopulation: successPopulation,
                sample: sample,
                population: population
            )
        }
        return chance
    }
    
    /// Holds the expected trick points won or lose when playing for a particular mix of suit and team
    struct PointsWhenPlaying {
        var lead = ExpectedPoints()
        var trump = ExpectedPoints()
        var other: ExpectedPoints
    }
    
    /// Returns the chance a card played of a suit is trumped by a team and the expected honor point value of the cards played by the team
    private func getChancesAndPoints(
        team: Team,
        suit: Suit,
        teamKnownState: [SeatKnown],
        points: PointsWhenPlaying)
    -> TrumpChanceAndExpectedPoints {
        
        // The return values
        var chancesAndPoints = TrumpChanceAndExpectedPoints()
        
        // Pooled if both team members are in the same state of certain knowlegde of  having suit or trump
        let pooledTeamState = teamKnownState.count == 2 && teamKnownState[0] == teamKnownState[1]
        
        // If the certain known states of the following team players are the same then their
        // probabilities of trumping are in a pooled state - so just have one pooled state
        // the probabilities still work as the underlying "chanceEmpty" functions take account
        // of the pooled state to calc the combined probability
        let seatStates = pooledTeamState ? teamKnownState.dropLast() : teamKnownState
        for seatKnown in seatStates {
            var cutTrumpChance = CanCutHasTrumpChance()
            
            // Set value for has trumps
            if seatKnown.hasTrumps {
                cutTrumpChance.hasTrumps = 1
            }
            else if seatKnown.emptyOfTrump {
                cutTrumpChance.hasTrumps = 0
            }
            else {
                cutTrumpChance.hasTrumps = chanceTeamHasTrumps(
                    seat: seat,
                    evalSuit: suit,
                    pooledState: pooledTeamState
                )
            }
            
            // Set value for can cut
            if seatKnown.emptyOfTrump {
                cutTrumpChance.canCut = 1
            }
            else {
                cutTrumpChance.canCut = chanceTeamEmptyOfSuit(
                    seat: seat,
                    suit: suit,
                    pooledState: pooledTeamState
                )
            }
            
            // Update return values
            chancesAndPoints.trumpChance += cutTrumpChance.trumpChance

            chancesAndPoints.expectedPoints += getSeatPoints(
                points: points,
                cutTrumpChance: cutTrumpChance
            )
        }
        
        return chancesAndPoints
    }
    
    ///  Get the summed expected points played by a seat given its PointsWhenPLaying and chance of cutting or trumping
    func getSeatPoints(points: PointsWhenPlaying, cutTrumpChance: CanCutHasTrumpChance) -> ExpectedPoints {
        var newPoints = ExpectedPoints()
        
        let chancePlaysLead: Double = (1 - cutTrumpChance.canCut)
        let chancePlaysTrump: Double = cutTrumpChance.trumpChance
        let chancePlaysOther: Double = 1 - chancePlaysLead - chancePlaysTrump
        
        newPoints += points.lead * chancePlaysLead
        newPoints += points.trump * chancePlaysTrump
        newPoints += points.other * chancePlaysOther
        
        return newPoints
    }
    
    /// Returns an analysis for each suit of for each team, the chance of winning and the expected points won or lost
    func getSuitTeamChancesAndPoints(eligible suits: Set<Suit>) -> SuitTeamChancesAndPoints {
        let teams = followingTeams()
        let expectedPoints = getExpectedPoints(suits: suits)
        let seatKnownState = getSuitTeamSeatKnown(eligible: suits)
        
        // Iterate over the suits in the player hand that are eligible to play
        var suitTeamChancesAndPoints = SuitTeamChancesAndPoints()
        for suit in suits {
            // ExpectedPoint object structure isn't symmetrical with teamBySuitTrumpChance
            // So have to partially init the "pointsWhenPlaying" in suits loop
            var pointsWhenPlaying = PointsWhenPlaying(other: expectedPoints.notLeadOrTrump[suit]!)
            
            // Create inner loop object
            var teamChanceAndPoints: [Team : TrumpChanceAndExpectedPoints] = followingTeams()
                .reduce(into: [:]) { $0[$1] = TrumpChanceAndExpectedPoints() }
            for team in teams {
                // Complete the points when playing object
                pointsWhenPlaying.trump = expectedPoints.trump[team]!
                pointsWhenPlaying.lead = expectedPoints.lead[suit]![team]!
                
                // Get the chances and points for mix of seatKnownState and expected points
                let chanceAndPoints = getChancesAndPoints(
                    team: team,
                    suit: suit,
                    teamKnownState: seatKnownState[suit][team]!,
                    points: pointsWhenPlaying
                )
                teamChanceAndPoints[team]! = chanceAndPoints
            }
            suitTeamChancesAndPoints[suit] = teamChanceAndPoints
        }
        return suitTeamChancesAndPoints
    }
    
    /// The players expectation of the remaining number of unplayed Trumps
    private func expectedTrumpCount() -> Int {
        let couldBeTrumpSuits = Set(Suit.allCases)
            .subtracting(game.round.suitsKnownCantBeTrump)
        
        // If only one suit not excluded then trump is known
        if couldBeTrumpSuits.count == 1 {
            return otherHandsAnalysis.suits[trump.suit!]!.count
        }
        // Otherwise calc the average for the possible trump suits
        else {
            let countPotentialTrumps: Int = couldBeTrumpSuits.reduce(into: 0) { result, suit in
                result += otherHandsAnalysis.suits[suit]!.count
            }
            
            let roundedAverage = Double(countPotentialTrumps) / Double(couldBeTrumpSuits.count)
            return Int(roundedAverage.rounded())
        }
    }
    
    /// The state of whether it is known as certain that a seat is empty of the lead suit in a trick, or if certain empty or has a trump
    struct SeatKnown: Equatable {
        var emptyOfLeadSuit: Bool = false
        var emptyOfTrump: Bool = false
        var hasTrumps: Bool = false
    }
    
    /// Returns the `SeatKnown` states for each following  player of a team in the trick  for the eligible suits
    private func getSuitTeamSeatKnown(eligible suits: Set<Suit>) -> SuitTeamSeatKnown {
        var suitKnown = SuitTeamSeatKnown()
        for suit in suits {
            var teamSeatKnownState: [Team : [SeatKnown]] = Team.allCases
                .reduce(into: [:]) { $0[$1] = [] }
            
            for seat in game.round.getSetofSeats(type: .following) {
                teamSeatKnownState[seat.team]!.append(getSeatKnownState(for: seat, lead: suit))
            }
            suitKnown[suit] = teamSeatKnownState
        }
        return suitKnown
    }
    
    /// Returns the SeatKnown state for a seat
    func getSeatKnownState(for player: Seat, lead: Suit) -> SeatKnown {
        var known = SeatKnown()
        
        // See playsuit suit to either the lead suit or trick leadSuit
        let playingSuit = currentTrick.isEmpty ? lead : currentTrick.leadSuit!
        
        if seatKnownEmptyOfSuit(player, playingSuit) || otherHandsAnalysis.isEmpty(of: playingSuit) {
            known.emptyOfLeadSuit = true
        }
        
        if trumpKnown
            && (seatKnownEmptyOfSuit(player, trump.suit!)
                || otherHandsAnalysis.isEmpty(of: trump.suit!))
            {
            known.emptyOfTrump = true
        }
        
        if trump.bidder == player && !trump.beenPlayed {
            known.hasTrumps = true
        }

        return known
    }

    /// Dictionary of the `CanCutHasTrumpChance` for suit and team
    struct SuitTeamSeatKnown {
        var chances: [ Suit: [ Team : [SeatKnown] ] ]  = Suit.allCases
            .reduce(into: [:]) { result, suit in
                result[suit] = [
                    .player : [],
                    .opponent : []
                ]
            }
        
        subscript(_ suit: Suit) -> [ Team : [SeatKnown] ] {
            get {
                return chances[suit]!
            }
            set(newValue) {
                chances[suit]! = newValue
            }
        }
    }
    
}
