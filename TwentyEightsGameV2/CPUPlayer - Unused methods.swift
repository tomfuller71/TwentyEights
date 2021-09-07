//
//  CPUPlayer - Unused methods.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import Foundation

/*

private func chanceTeamTopSuit(
    seat: Seat,
    card: Card,
    otherHands: OtherHandsAnalysis,
    following: Following) -> Double {
    
    // Constants used in all cases
    let suit = currentTrick.isEmpty ? card.suit : currentTrick.leadSuit!
    let topRank = currentTrick.isEmpty ? 0 : otherHands.suits[suit]!.topRank
    
    let partnerWinning = currentTrick.winningSeat == seat.partner
    
    let partnerCanPlay: Bool = following.seats_OfGroup_Not_EmptyofSuit(
        seat.partnerGroup, card.suit).count > 0
    
    let opposingSeatsNotEmptyYetToPlay: Int = following.seats_OfGroup_Not_EmptyofSuit(
        seat.partnerGroup.opposingTeam, card.suit).count
    
    let opposingCanPlay = opposingSeatsNotEmptyYetToPlay > 0
    
    let cardSuitCanWin = currentTrick.isEmpty || card.suit == currentTrick.leadSuit
        || (trump.isCalled && card.suit == trump.suit)
    
    let highestTeamCardRank = max(
        partnerWinning ? currentTrick.winningRank : 0,
        cardSuitCanWin ? card.currentRank : 0
    )
    
    let bestCurrentRank: Int = max(highestTeamCardRank, currentTrick.winningRank)
    
    let certainToWin = highestTeamCardRank > topRank
        || (!opposingCanPlay && highestTeamCardRank > currentTrick.winningRank)
    
    let certainToLose = highestTeamCardRank < currentTrick.winningRank && !partnerCanPlay
    
    // Computed vars used only in parts of logic tree (and then once)
    let countBetterRankedCards: [Card] = otherHands.suits[suit]!.cards
            .filter { $0.currentRank > bestCurrentRank }
    
    let seatsThatCanHaveSuits: Int = 3 - following.seatsKnownEmptyForSuit[card.suit]!.count
    
    // Logic for determining win chance for team for a given card
    if certainToWin {
        return 1
    }
    else if certainToLose {
        return 0
    }
    // Otherwise need to calculate chances for cases where
    else if partnerCanPlay && !opposingCanPlay {
        //chance that partner has 1 or more of betterCards.count from remaining population
        // 1 - chance of having 0
        
        return 1 - hyperGeoProb(
            success: 0,
            successPopulation: countBetterRankedCards.count,
            sample: handSize,
            population: handSize * seatsThatCanHaveSuits
        )
    }
    else if !partnerCanPlay && opposingCanPlay {
        // Chance that the opponent has a higher card than your current winning rank
        // (as if wasn't winning would be caught in certain to lose earlier)
        // 1 - chance opps have zero higher cards

        return 1 - hyperGeoProb(
            success: 0,
            successPopulation: countBetterRankedCards.count,
            sample: handSize * opposingSeatsNotEmptyYetToPlay,
            population: handSize * seatsThatCanHaveSuits
        )
    }
    else if partnerCanPlay && opposingCanPlay {
        // Only one can have the top rank so simplify and assume chance of having the top rank
        // are equal over the remaining card can play seats (assumes players didnt finesse)
        print("win chance \(Double(1 / (1 + opposingSeatsNotEmptyYetToPlay)))")
        return Double(1 / (1 + opposingSeatsNotEmptyYetToPlay))
    }
    else {
        fatalError("shouldn't have got here - all cases should be in logic above")
        return 0
    }
}
 
 */
