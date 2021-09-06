//
//  SuitEvaluation.swift
//  SuitEvaluation
//
//  Created by Thomas Fuller on 9/3/21.
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
    
    /// Dictionary of the `CanCutHasTrumpChance` for suit and team
    struct SuitCutTrumpTeamChance {
        var chances: [Suit: [Team : CanCutHasTrumpChance]]  = Suit.allCases
            .reduce(into: [:]) { result, suit in
                result[suit] = [
                    .player : CanCutHasTrumpChance(),
                    .opponent : CanCutHasTrumpChance()
                ]
            }
        
        subscript(_ suit: Suit) -> [Team : CanCutHasTrumpChance] {
            get {
                return chances[suit]!
            }
            set(newValue) {
                chances[suit]! = newValue
            }
        }
    }
    
    /// A structure that holds for each suit  a dictionary of a teams 'ChancesAndPoints'
    struct SuitTeamChancesAndPoints {
        var analysis: [Suit: [Team : ChancesAndPoints]]  = Suit.allCases
            .reduce(into: [:]) { result, suit in
                result[suit] = [
                    .player : ChancesAndPoints(),
                    .opponent : ChancesAndPoints()
                ]
            }
        
        subscript(_ suit: Suit) -> [Team : ChancesAndPoints] {
            get {
                return analysis[suit]!
            }
            set(newValue) {
                analysis[suit]! = newValue
            }
        }
    }
    
    /// A structure that hold the chances of a card of a suit being trumped and the expected trick point won or lost
    struct ChancesAndPoints {
        var trumpChance = CanCutHasTrumpChance()
        var expectedPoints = ExpectedPoints()
    }
    
    /// Returns the `CanCutAndTrumpState` for a player yet to play in the trick given suit being evaluated
    private func getCanCutHasTrumpTeamChance(eligible suits: Set<Suit>) -> SuitCutTrumpTeamChance {
        var suitChancesDict = SuitCutTrumpTeamChance()
        
        for suit in suits {
            var cutTrumpTeamChance: [Team : CanCutHasTrumpChance] = Team.allCases
                .reduce(into: [:]) { $0[$1] = CanCutHasTrumpChance() }
            
            for team in Team.allCases {
                cutTrumpTeamChance[team] = getCutTrumpChance(for: team, suit: suit)
            }
            suitChancesDict[suit] = cutTrumpTeamChance
        }
        
        return suitChancesDict
    }
    
    /// Return the `CanCutHasTrumpChance` for a given suit and team
    private func getCutTrumpChance(for team: Team, suit: Suit) -> CanCutHasTrumpChance {
        // Assume unknown unless no more of that suit or player known empty
        var chance = CanCutHasTrumpChance()
        
        // Certain to cut if suit empty or team empty of suit
        if otherHandsAnalysis.suits[suit]!.count != 0
            || !following.seats_OfGroup_EmptyofSuit(team, suit).isEmpty {
            chance.canCut = 1
        }
        else {
            chance.canCut = chanceTeamEmptyOfSuit(team: team, suit: suit)
        }
        
        // Certain have trumps if bidding team hasn't played its trump yet
        if trump.bidder?.team == team && !trump.beenPlayed {
            chance.hasTrumps = 1
        }
        else {
            chance.hasTrumps = chanceTeamHasTrumps(team: team, evalSuit: suit)
        }
        
        return chance
    }
    
    /// Returns chance that team is empty of given suit
    private func chanceTeamEmptyOfSuit(team: Team, suit: Suit) ->  Double {
        let population = game.round.seatsNotEmptyOf(suit).count * handSize
        let sample = following.seats_OfGroup_Not_EmptyofSuit(team, suit).count * handSize
        
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
    private func chanceTeamHasTrumps(team: Team, evalSuit: Suit) ->  Double {
        var successPopulation:Int = 0
        var sample: Int = 0
        var population:Int = 0
        
        if trumpKnown {
            successPopulation = otherHandsAnalysis.suits[trump.suit!]!.count
            sample = following.seats_OfGroup_Not_EmptyofSuit(team, trump.suit!).count * handSize
            population = game.round.seatsNotEmptyOf(evalSuit).count * handSize
        }
        else {
            successPopulation = expectedTrumpCount(excluding: evalSuit)
            sample = following.seatsofGroup(team).count * handSize
            population = otherHandsAnalysis.population
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

    //TODO: - Complete to mix the chances and expected values combined
    private func getChancesAndPoints(
        points: PointsWhenPlaying,
        cutChances: CanCutHasTrumpChance) -> ChancesAndPoints {
            
        var returnEval = ChancesAndPoints()
        
        return returnEval
    }
    
    /// Returns an analysis for each suit of for each team, the chance of winning and the expected points won or lost
    private func suitAnalysis(eligible suits: Set<Suit>) -> SuitTeamChancesAndPoints {
        let expectedPoints = getExpectedPoints(suits: suits)
        let teamBySuitTrumpChance = getCanCutHasTrumpTeamChance(eligible: suits)
        
        var suitTeamChancesAndPoints = SuitTeamChancesAndPoints()
        
        // Iterate over the suits in the player hand that are eligible to play
        for suit in suits {
            // ExpectedPoint object structure isn't symmetrical with teamBySuitTrumpChance
            // So have to partially init the "pointsWhenPlaying" in suits loop
            // And then complete in team loop - not ideal maybe refactor
            var pointsWhenPlaying = PointsWhenPlaying(other: expectedPoints.notLeadOrTrump[suit]!)
            
            // Create inner loop object
            var teamChanceAndPoints: [Team : ChancesAndPoints] = following.teamsYetToPlay
                .reduce(into: [:]) { $0[$1] = ChancesAndPoints() }
            
            // Iterate over teams
            for team in Team.allCases {
                // Complete the points when playing object
                pointsWhenPlaying.trump = expectedPoints.trump[team]!
                pointsWhenPlaying.lead = expectedPoints.lead[suit]![team]!
                
                // Get the chances and points for mix of trump chances and expected points
                teamChanceAndPoints[team] = getChancesAndPoints(
                    points: pointsWhenPlaying,
                    cutChances: teamBySuitTrumpChance[suit][team]!
                )
            }
            
            suitTeamChancesAndPoints[suit] = teamChanceAndPoints
        }
        return suitTeamChancesAndPoints
    }
    
    /// The players expectation of the remaining number of unplayed Trumps
    private func expectedTrumpCount(excluding evalSuit: Suit) -> Int {
        let couldBeTrumpSuits = Set(Suit.allCases)
            .subtracting(game.round.suitsKnownCantBeTrump)
            .subtracting(Set([evalSuit]))
        
        let countPotentialTrumps: Int = couldBeTrumpSuits.reduce(into: 0) { result, suit in
                result += otherHandsAnalysis.suits[suit]!.count
        }
        
        let roundedAverage = Double(countPotentialTrumps) / Double(couldBeTrumpSuits.count)
        return Int(roundedAverage.rounded())
    }
    
}
