//
//  ExpectedPoints.swift
//  ExpectedPoints
//
//  Created by Thomas Fuller on 9/3/21.
//

import Foundation

extension CPUPlayer {
    
    /// The expected points for a card of that suit played by a subsequent PartnerGroup under the assumption that they are playing to win the trick and under the assumption that they are playing to lose
    struct ExpectedPoints {
        var winning: Double = 0.0
        var losing: Double = 0.0
    }
    
    /// The expected points for a card of the lead, trump or other suit played by a subsequent player of a PartnerGroup when max if winning or min if losing the total trick points
    struct SuitExpectedPoints {
        var lead: [Suit : [Team : ExpectedPoints]]
        var trump: [Team : ExpectedPoints]
        var notLeadOrTrump: [Suit : ExpectedPoints]
        
        init() {
            let empty:[Team : ExpectedPoints] = [
                .player : ExpectedPoints(),
                .opponent: ExpectedPoints()
            ]
            
            self.lead = Suit.allCases.reduce(into: [:]) { $0[$1] = empty }
            self.trump = empty
            self.notLeadOrTrump = Suit.allCases.reduce(into: [:]) { $0[$1] = ExpectedPoints() }
        }
    }
    
    /// Get the `SuitExpectedPoints`
    func getExpectedPoints(suits: Set<Suit>) -> SuitExpectedPoints {
        var expectedPoints = SuitExpectedPoints()
        
        // For each suit being evaluated
        for suit in suits {
            // Analyse the lead suit if not empty
            if !otherHandsAnalysis.suits[suit]!.honorCards.isEmpty {
                if trumpKnown && suit == trump.suit! {
                    expectedPoints.trump = getPointsForSuit(suit: trump.suit!)
                }
                else {
                    expectedPoints.lead[suit] = getPointsForSuit(suit: suit)
                }
            }
            
            // Calc the expected points if not playing either lead or trump
            expectedPoints.notLeadOrTrump[suit] = avgPointsIfNotLeadOrTrump(excluding: suit)
        }
        
        return expectedPoints
    }
    
    
    /// Returns for each partner group the expected points total if that group where expecting to win or lose for the remaining cards to be played in a trick
   private func getPointsForSuit(suit: Suit)
    -> [Team : ExpectedPoints] {
        
        var pointsByGroup: [Team : ExpectedPoints] = [
            .opponent : ExpectedPoints(),
            .player : ExpectedPoints()
        ]
        
        let honorCards = otherHandsAnalysis.suits[suit]!.honorCards
        
        let winningPoints = pointsPerCardInHandState(honorCards: honorCards, winning: true)
        let losingPoints = pointsPerCardInHandState(honorCards: honorCards, winning: false)
        
        
        for group in Team.allCases {
            let seats = following.seats_OfGroup_Not_EmptyofSuit(group, suit)
            
            // Early continue this loop if no seats for group
            if seats.isEmpty { continue }
            
            var avgSumPoints = ExpectedPoints()
            var denominator = 1.0
            
            for n in 0 ... (honorCards.count - 1)  {
                
                let chanceOfPooledNCards = hyperGeoProb(
                    success: n,
                    successPopulation: honorCards.count,
                    sample: handSize * seats.count,
                    population: otherHandsAnalysis.population)
                
                var stateSum = ExpectedPoints()
                
                // For one (or zero) hands we are simply adding the expected points values if honor cards == n
                if seats.count < 2 {
                    stateSum.winning += winningPoints[n]
                    stateSum.losing += losingPoints[n]
                }
                else {
                    /* For pooled hands we have to get the average expected value for the pool having n honor cards combined
                     Each pool of hands can exist in a number of different states.  For example if there a 4 remaining honor honorCards, then an team could have any combination of Ints
                     that collective adds to any value between 0 and 4. i.e. if there are 3 honor honorCards remaining there are 6 summed value state (2 + 2 + 1 + 1).
                     */
                    
                    /// Array of opponent  pairs of honor points honorCards in each  hand for unknown pooled states of 0,1,2,3,4
                    let honorComboStates: [[(Int,Int)]] = [
                        [(0,0)],
                        [(1,0)],
                        [(2,0), (1,1)],
                        [(3,0), (2,1)],
                        [(4,0), (3,1), (2,2)]
                    ]
                    
                    let opponentCardCountPairs = honorComboStates[n]
                    
                    // For each potential pair of values that sum to n
                    for pair in opponentCardCountPairs {
                        stateSum.winning += winningPoints[pair.0] + winningPoints[pair.1]
                        stateSum.losing += losingPoints[pair.0] + losingPoints[pair.1]
                    }
                    
                    denominator = Double(opponentCardCountPairs.count * seats.count)
                }
                
                // Weighting the expected points value for n Honor cards by probability of having n honor cards
                avgSumPoints.winning += stateSum.winning / denominator * chanceOfPooledNCards
                avgSumPoints.losing += stateSum.losing / denominator * chanceOfPooledNCards
            }
            // Add to the return dictionary
            pointsByGroup[group] =  avgSumPoints
        }
        return pointsByGroup
    }
    
    /// The expected average value for the first value in an array passed into it of remaining honors (if winning sort high to low, if losing low to high) for a assumed array of honorCards
    private func pointsPerCardInHandState(honorCards: [Card], winning: Bool) -> [Double] {
        /*
         The expectation is that if you are playing the top card your opponent will rationally play the lowest honor they have, and your partner would play the highest they have,
         and vice versa if playing playing a card to lose to the opponent.
         
         If it is not know that a player is empty of the suit in question, then then can potentially have any number of honor cards in their hand from 0 ... count of remaining honor cards of suit.
         
         For each of these states 0... honorCount there is a different expectation of the card value.
         If player has just 1 honor card then it is simply an expectation that of the average points value for the remaining honor cards.
         If you have all of the remaing honors then the expected card played would be either the lowest or highest of the remaining honor cards (as no chance not in hand)
         
         The only two remaining scenarios are for combination 4C2 or 3C2 (where count is 2) and 4C3:
         - For 4C3 the distribution is simple, out of 4 scenarios there is only one scenario where player doesn't have either highest/lowest card and in that case they must have the second lowest/ highest.
         - For 4C2 or 3C2 the different potential distributions have to be iterated through for each potential state of mix of high and low cards.
         */
        
        if honorCards.isEmpty { return [0] }
        
        let sorted = winning ?
        honorCards
            .sorted { $0.face.points > $1.face.points }
        :
        honorCards
            .sorted { $0.face.points < $1.face.points }
        
        let remainingHonors = sorted.map { $0.face.points }
        
        
        var expectedPoints: [Double] = []
        for n in 0...remainingHonors.count {
            
            var combinations: Double {
                factorial(remainingHonors.count)
                / ( factorial(n) * factorial(remainingHonors.count - n) )
            }
            
            if (remainingHonors.count - n) == 0 {
                expectedPoints.append(Double(remainingHonors[0]))
            }
            else {
                switch n {
                case 0:
                    expectedPoints.append(0)
                    
                case 1:
                    expectedPoints.append(
                        Double(remainingHonors.reduce(0, + )) / Double(remainingHonors.count))
                    
                case 2:
                    var topSum: Double = 0
                    for i in 0 ... (remainingHonors.count - n) {
                        topSum +=
                        Double((remainingHonors.count - 1) - i)
                        * Double(remainingHonors[i])
                    }
                    expectedPoints.append(topSum / combinations)
                    
                case 3:
                    expectedPoints.append(
                        Double(
                            ((remainingHonors.count - 1) * remainingHonors[0] + remainingHonors[1]))
                        / combinations
                    )
                    
                default:
                    print("error")
                }
            }
        }
        return expectedPoints
    }
    
    /// Returns the average honor points per cards in the deck that excludes cards of the current player, and cards of  the lead suit and optionally the trumpSuit
    private func avgPointsIfNotLeadOrTrump(excluding leadSuit: Suit) -> ExpectedPoints {
        
        let nonSuitNonTrumpCards: [Card] = Suit.allCases.reduce(into: []) { cards, suit in
            if suit != leadSuit && !( trumpKnown && suit == trump.suit! ) {
                cards.append(contentsOf: otherHandsAnalysis.suits[suit]!.cards)
            }
        }
        
        let nonSuitHonorCards: [Int] = Suit.allCases.reduce(into: []) { cards, suit in
            if suit == leadSuit || suit == trump.suit! {
                cards.append(
                    contentsOf: otherHandsAnalysis.suits[suit]!.honorCards
                        .map { $0.face.points }
                )
            }
        }
        
        // Provided at least one honor card remaining calc the expected points
        if nonSuitHonorCards.isEmpty {
            return ExpectedPoints(winning: 0, losing: 0)
        }
        else {
            let honorPoints: Int = nonSuitHonorCards.reduce(0, +)
            let avgHonorPoints = Double(honorPoints) / Double(nonSuitHonorCards.count)
            let proportionHonours = Double(nonSuitHonorCards.count) / Double(nonSuitNonTrumpCards.count)
            
            return ExpectedPoints(winning: avgHonorPoints, losing: proportionHonours * avgHonorPoints)
        }
    }
}
