//
//  CPUPlayer.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/10/21.
//

import Foundation
import Combine

class CPUPlayer {
    /// Shared game model for game of 28s
    private var game: GameController
    
    /// Respond to game active seat changing
    private var activeCPUSeat: Seat?
    
    private var activeCancellable: AnyCancellable?
    
    /// Array of Doubles for factorial values up to 32
    private let factorials32: [Double] = {
        var facts: [Double] = []
        for  i in 0 ... 32 {
            let fact =  i > 0 ? (1 ... i).map(Double.init).reduce(1.0, *)  :  1
            facts.append(fact)
        }
        return facts
    }()
    
    init(game: GameController) {
        self.game = game
        self.activeCancellable = self.game.$active.sink { seat in
            if self.game.players[seat]!.playerType == .localCPU {
                self.activeCPUSeat = seat
                self.takeAction()
            }
        }
    }
}

extension CPUPlayer {
    //MARK: - CPU Player action
    private func takeAction() {
        let seat = activeCPUSeat!
        let actionType: PlayerAction.ActionType =  getActionType(seat)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay) {
            self.game.respondToPlayerAction(
                PlayerAction(seat: seat, type: actionType)
            )
        }
    }
        
    private func getActionType(_ seat: Seat) -> PlayerAction.ActionType {
        // Take action if seat set to non-nil value
        if isBidding {
            return makeBid()
        }
        // Otherwise play in trick
        else if seatShouldCallTrump(seat) {
            return .callForTrump
        }
        else {
           return playInTrick(seat)
        }
    }
    
    private func makeBid() -> PlayerAction.ActionType {
        let suggestedBid = selectBestBid()
        
        if let bid = suggestedBid {
            return .makeBid(bid)
        }
        else {
            return .pass(stage: game.round.bidding.stage)
        }
    }
    
    private func seatShouldCallTrump(_ seat: Seat) -> Bool {
        guard game.round.canSeatCallTrump(seat) && game.seatJustCalledTrump == nil else {
            return false
        }
        return true
    }
    
    
    private func playInTrick(_ seat: Seat) -> PlayerAction.ActionType {
        let eligibleCards = game.round.getEligibleCards(
            for: seat,
            seatJustCalled: game.seatJustCalledTrump != nil
        )
        
        if eligibleCards.count == 1 {
            return .playCardInTrick(eligibleCards[0])
        }
        else {
            let bestCard = selectBestCardToPlay(from: eligibleCards)
            return .playCardInTrick(bestCard)
        }
    }
    
    // MARK:- Commmon computed properties & methods
    
    /// True if the game is currently in either the first or second stage of bidding
    private var isBidding: Bool {
        if case .bidding(_) = game.round.stage { return true } else { return false }
    }
    
    /// Current hand size for the AI player
    private var handSize: Int { _28s.initalHandSize - game.round.trickCount }
    
    /// Returns true is the provided Seat is the bidder
    private var isBidder: Bool {
        if let seat = activeCPUSeat {
            return seat == game.round.bidding.winningBid?.bidder
        }
        else {
            return false
        }
    }
    
    /// Returns true if the provided card is the same suit as the trump card
    private func isTrumpSuit(_ card: Card) -> Bool {
        card.suit == game.round.trump.card?.suit
    }
    
    private func trumpIsKnowntoPlayer(_ seat: Seat) -> Bool {
        game.round.trump.isCalled || isBidder
    }
}




extension CPUPlayer {
    //MARK: - AI Bidding
    
    /*
     - Using arbitary pseudo logic to score the bidding value of a hand (its bid points) and the best card to select as a trump.
     Method calculates a  difference from the mean expected bidPoints in a hand and the actual bidPoints in a hand,
     and then uses that delta as a increment to the min bid.
     
     - To calculate "bidPoints" only two factors are considered; the honor point values of the actual cards, and additional points
     for long suits (as it is assumed that they will be the trump).
     
     - If game.defaults UserDefaults key is set to isCautiousBidder then the bidPoints evalution reduces the bidPoints if a suit has a singleton non Jack honor card
     
     - The logic for selected the card is simple.  Select the lowest card of the suit with the most bid points, and if two suits
     share the same # of bid points then pick the longest of those suits.
     
      - In deciding to bid of pass the simple logic is used
         - only bid if expected point are more than the minBidBuffer above the current minBid
         - if you can pass do so unless you are above the threshold
     */
    
 /// Select the best bid to make or return nil to pass
    private func selectBestBid() -> Bid? {
        let minBid: Int = game.round.bidding.bidMinForSeat(activeCPUSeat!)
        
        var suggestedBid: Bid = suggestBid()
        
        var overBidThreashold: Bool { ((minBid + _28s.minBidBufffer) < suggestedBid.points) }
        
        if !overBidThreashold {
            if activeCPUCanPass {
                return nil
            }
            else {
                suggestedBid.points = minBid
            }
        }
        return suggestedBid
    }
    
    
    /// Whether the activeCPU player can pass
    private var activeCPUCanPass: Bool {
        activeCPUSeat != game.round.starting || game.round.bidding.winningBid != nil
    }
    
    /// Determine a suggested bid
    private func suggestBid() -> Bid {
        let hand = game.round.hands[activeCPUSeat!]
        let handEvaluation = evaluateHand(hand: hand)
        
        var expectedPointsForStage: Double {
            if game.round.stage == .bidding(.first) {
                return Double(_28s.pointsInDeck) / 8.0
            }
            else {
                return Double(_28s.pointsInDeck) / 4.0
            }
        }
        
        let bidDelta: Double = handEvaluation.points - expectedPointsForStage
        
        // Calculate round up Int bid based on mean combined team honor points of 14 plus delta
        let bidpoints = Int( (14.0 + bidDelta).rounded(.up) )
        
        let selectedCard = hand.filter { $0.suit == handEvaluation.bestSuit }
            .sorted { $0.face.rank < $1.face.rank }.first!
        
        return Bid(
            points: bidpoints,
            card: selectedCard, bidder: activeCPUSeat!
            //stage: game.round.bidding.stage
        )
    }
    
    
    /// Get the evaluated expected bid points for hand and best suit to Bid
    private func evaluateHand(hand: Hand) -> (points: Double, bestSuit: Suit) {
        assert(!hand.isEmpty, "Hand is empty cannot bid")
        
        struct BiddingSuitEvalution {
            var suit: Suit
            var suitCount: Int
            var points: Double
        }
        
        let isCautiousBidder = game.defaults.bool(forKey: "isCautiousBidder")
        
        let suits: Set<Suit> = hand.reduce(into: []) { result, card in
            result.insert(card.suit)
        }
        
        // Evaluate each suit in hand
        let evaluations: [BiddingSuitEvalution] = suits.reduce(into: []) { result, suit in
            let suitCards: [Card] = hand.filter { $0.suit == suit }
            let count = suitCards.count
            let excessSuitCards: Double = max(0.0, Double(count - _28s.extraCardofSuitLimit))
            
            var points: Double = suitCards.reduce(into: 0) { result, card in
                result += Double(card.face.points)
            }
            
            points += excessSuitCards * _28s.bidPointsPerExtraCard
            
            // Change point evaluation if user defaults set to cautious Bidder and Singleton honor
            if isCautiousBidder && count == 1 {
                let singleton = suitCards.first!
                if singleton.face != .jack {
                    points -= points / 2
                }
            }
            
            result.append(BiddingSuitEvalution(suit: suit, suitCount: count, points: points))
        }
        
        // Determine the best suit (most points or longest if all 0)
        var bestSuit: Suit {
            let bestEvalByPoints = evaluations.sorted { $0.points > $1.points }.first!
            
            if bestEvalByPoints.points > 0 {
                return bestEvalByPoints.suit
            }
            else {
                return evaluations.sorted { $0.suitCount > $1.suitCount }.first!.suit
            }
        }
        
        // Sum the total points in hand
        let totalPoints: Double = evaluations.reduce(into: 0.0) { result, eval in
            result += eval.points
        }
 
        return (points: totalPoints, bestSuit: bestSuit)
    }
    
}



extension CPUPlayer {
    //MARK: - AI Playing in Trick
    /*
     - The best card to play is the one that yields the highest EV of honor points for the team
     
     - The net EV of any given card is the the expected trick Value if a winner minus the expected trick Value if a loser
     - The EV winning is the chance of team winning * the estimated honor points in a trick in which it is assumed the opponent will limit their point lost
     - The EV losing is the chance of team losing * the estimated honor points in a trick where it is assumed that the partner will limit their points lost
     
     - The chance of winning is a simple estimation that assumes that topRank card needed to win will have been played early in the round if it was available (no-finessing)
     unless the player is last to play and it is clear what the winning rank was not played
     
     - The "winning" chance = (chance of Team Having Top rank and not being trumped by anyone) + (chance Team itself Trumps and the opponent doesn't overtrump)
     
     - Chance of being trumped is probability based on a large number of factors representing the knowledge the player would have of:
     - the number of players yet to play in trick,
     - the trump card if they are the bidder or if it's been called,
     - whether any remaining players are known to be empty of the eligible cards suit,
     - the maximum number of trump cards remaining,
     - whether any remaining players in the trick don't have trumps,
     - if the top trump cards has already been played
     
     - Based on the sum of this knowledge the likelihood of either any given card being either successfully trumped by the opposing team or by your own playing partner
     */
    
    
    
    typealias OtherHands = [Suit: (count: Int, topRank: Int, honorPoints: Int)]
    

    
    /// Return the best card to play from an array of cards that are eligible to play, if reRun is true then we are calc the chance of next best card leading off the trick
    private func selectBestCardToPlay(from eligibleCards: [Card]) -> Card {
        guard let seat = activeCPUSeat else { fatalError("activeCPUSeat nil in error") }
        
        // Get the current trick and remaining cards state
        let otherHandsCards: OtherHands = otherPlayerCardsBySuit()
        
        // Minimum suit that need to be analysed
        var minSuits: Set<Suit> {
            var suits = Set<Suit>()
            if !game.round.currentTrick.isEmpty {
                suits.insert(game.round.currentTrick.leadSuit!)
            }
            if trumpIsKnowntoPlayer(seat) {
                suits.insert(game.round.trump.card!.suit)
            }
            return suits
        }
        
        // Eligible suits union with min Suits
        var eligibleSuits: Set<Suit> = Set(eligibleCards.map { $0.suit })
        eligibleSuits.formUnion(minSuits)
        
        let following: Following = Following(
            seats: game.round.currentTrick.followingSeats,
            emptySuits: game.round.seatsKnownEmptyForSuit)
        
        // For each eligible suit, and team, get chance that a card of suit would be trumped by the team, and the expected points value of the card(s) played by the team
        let suitAnalysis: BestSuitToPlayAnalysis = getSuitAnalysis(
            for: seat,
            following: following,
            eligible: eligibleSuits,
            otherHandsCards: otherHandsCards)
        
        // Get the chance that an opponent has a higher trump than your partner
        let trumpTopRank: Int = otherHandsCards[game.round.trump.card!.suit]!.topRank
        let chanceOpTrumpHigher: Double =  chanceOppHigherTrumpThanPartner(
            seat: seat,
            following: following,
            topRank: trumpTopRank)
        
        // Get the array of probabilities for each card
        var cardProbabilities: [CardEvaluation] = []
        
        for card in eligibleCards {
            // Determine relevant suit
            let suit = game.round.currentTrick.isEmpty ? card.suit : game.round.currentTrick.leadSuit!
            
            // Determine chance the player team has the top ranked card that could win a trick if not trumped
            let chanceTeamTopRank = chanceTeamHasSuitTopRank(
                card: card,
                suitTopRank: otherHandsCards[suit]!.topRank,
                following: following.seats)
            
            // Determine chance of card being trumped
            var trumpChances: (partner: Double, opponent: Double) {
                var chances = (partner: 0.0, opponent: 0.0)
                if (game.round.trump.isCalled && card.currentRank > trumpTopRank) {
                    return chances
                }
                else {
                    chances.partner = suitAnalysis[suit][seat.partnerGroup].trumpChance
                    chances.opponent = suitAnalysis[suit][seat.partnerGroup.opposingTeam].trumpChance
                }
                return chances
            }
            
            // Calculated chance of player's team winning given with the card being evaluated
            let chanceTeamTopCardOfSuitWins: Double = chanceTeamTopRank
                * (1 - min(1, (trumpChances.partner + trumpChances.opponent)))
            
            let chancePartnerAloneTrumps: Double = trumpChances.partner
                * (1 - trumpChances.opponent)
            
            let chancePartnerOverTrumps: Double = trumpChances.partner
                * trumpChances.opponent * (1 - chanceOpTrumpHigher)
            
            let chancePartnerCardTrumpsAndWins = chancePartnerAloneTrumps + chancePartnerOverTrumps
            let chanceTeamWinning = chanceTeamTopCardOfSuitWins + chancePartnerCardTrumpsAndWins
            
            // Calculating the expected points won or lost
            let current = Double(game.round.currentTrick.pointsInTrick + card.face.points)
            let trickPointValue = (
                // Partner trying to maximise pts opponent trying to minimise points
                winPoints: current
                    + suitAnalysis[suit][seat.partnerGroup].expectedPoints.winning
                    + suitAnalysis[suit][seat.partnerGroup.opposingTeam].expectedPoints.losing,
                
                // Partner trying to minimise pts opponent trying to maximise points
                losePoints: current
                    + suitAnalysis[suit][seat.partnerGroup].expectedPoints.losing
                    + suitAnalysis[suit][seat.partnerGroup.opposingTeam].expectedPoints.winning)
            
            if trickPointValue.winPoints > 7 && game.seatJustCalledTrump != nil
                || trickPointValue.winPoints == .nan
                || trickPointValue.losePoints > 7 && game.seatJustCalledTrump != nil
                || trickPointValue.losePoints == .nan
            {
                print("Something ain't right")
            }

            let netPoints = chanceTeamWinning
                * trickPointValue.winPoints
                - (1 - chanceTeamWinning) * trickPointValue.losePoints
            
            // Testing print out values for card evaluated
            let printText: String =
                "\(card.text) top: \(String(format: "%.1f%%", chanceTeamTopRank * 100))"
                + " Trump - any: "
                + String(
                    format: "%.1f%%",
                    min(1,(trumpChances.partner + trumpChances.opponent)) * 100
                )
                + "p: \(String(format: "%.1f%%", trumpChances.partner  * 100))"
                + " o: \(String(format: "%.1f%%", trumpChances.opponent  * 100))"
                + " Op>T \(String(format: "%.1f%%", chanceOpTrumpHigher  * 100))"
                + " Win: \(String(format: "%.1f%%", chanceTeamWinning  * 100))"
                + " TrickPoints - win: \(String(format: "%.2f%", trickPointValue.winPoints))"
                + " lose: \(String(format: "%.2f%", trickPointValue.losePoints))"
                + " netEp: \(String(format: "%.2f%", netPoints))"
            print(printText)
            
            cardProbabilities.append(
                CardEvaluation(
                    card: card,
                    winChance: chanceTeamWinning,
                    trickPointValue: trickPointValue)
            )
        }
        
        // Sort by EV and then winChance
        cardProbabilities.sort {
            ($0.netExpectedPoints, $0.winChance) > ($1.netExpectedPoints, $1.winChance)
        }
        
        // While not implementing reflow, assume that always play best EV card ...
        // ... unless the first card is the unbeatable in the future - and the second card is also guaranteed to win
        let first = cardProbabilities[0].card
        let second = cardProbabilities[1].card
        
        var firstCardUnbeatable: Bool {
            var unbeatable = false
            if trumpIsKnowntoPlayer(seat) {
                if first.currentRank > otherHandsCards[game.round.trump.card!.suit]!.topRank {
                    unbeatable = true
                }
                else if otherHandsCards[game.round.trump.card!.suit]!.count == 0
                            && first.currentRank > otherHandsCards[first.suit]!.topRank {
                    unbeatable = true
                }
            }
            return unbeatable
        }
        print("\(firstCardUnbeatable && cardProbabilities[1].winChance == 1 ? second.text : first.text)")
        return (firstCardUnbeatable && cardProbabilities[1].winChance == 1) ? second : first
    }
    
    /// Returns the average honor points per cards in the deck that excludes cards of the current player, and cards of  the lead suit and optionally the trumpSuit
    private func getAvgHonorPointsInOtherHandsExcluding(
        player seat: Seat,
        lead leadSuit: Suit,
        trump trumpsuit: Suit?
    ) -> ExpectedPoints {
        
        let nonSeatNonSuitCards = game.round.hands.remainingCardsExcludingSeat(seat)
            .filter {$0.suit == leadSuit || $0.suit == trumpsuit }
        
        let nonSuitHonorCards: [Int] = nonSeatNonSuitCards
            .filter { $0.face.points > 0 }
            .map { $0.face.points }
        
        // Provided at least one honor card remaining calc the expected points
        if nonSuitHonorCards.isEmpty {
            return ExpectedPoints(winning: 0, losing: 0)
        }
        else {
            let honorPoints: Int = nonSuitHonorCards.reduce(0, +)
            let avgHonorPoints = Double(honorPoints) / Double(nonSuitHonorCards.count)
            let proportionHonours = Double(nonSuitHonorCards.count) / Double(nonSeatNonSuitCards.count)
            
            return ExpectedPoints(winning: avgHonorPoints, losing: proportionHonours * avgHonorPoints)
        }
    }
    
    /// Returns a dictionary hold for each suit  a tuple of count or remaining cards and the top rank in other players hands
    private func otherPlayerCardsBySuit() -> OtherHands {
        var remaining: [ Suit : (count: Int, topRank: Int, honorPoints: Int) ] = [:]
        for suit in Suit.allCases {
            remaining[suit] = (count: 0, topRank: 0, honorPoints: 0)
        }
        
        for card in otherPlayerCards() {
            remaining[card.suit]!.count += 1
            remaining[card.suit]!.honorPoints += card.face.points
            if (card.currentRank > remaining[card.suit]!.topRank) {
                remaining[card.suit]!.topRank = card.currentRank
            }
        }
        return remaining
    }
    
    /// The players expectation of the remaining number of unplayed Trumps ( used in determining probability of a card being trumped)
    private func expectedTrumpCountWhenPlayingSuit(
        suit: Suit,
        remainingSuitCards: OtherHands
    ) -> Int {
        // Expected number of trumps is the rounded average of the suit counts for suits that could
        // possibly trump the card
        
        var potentialSuitCount: Int = 0
        var totalCount: Int = 0
        
        for suit in Suit.allCases {
            let suitCount = remainingSuitCards[suit]!.count
            let couldBeTrumpSuit = !game.round.suitsKnownCantBeTrump.contains(suit)
            
            if suitCount > 0 && couldBeTrumpSuit {
                totalCount += suitCount
                potentialSuitCount += 1
            }
        }
        
        let roundedAverage = Double(totalCount / potentialSuitCount).rounded()
        return Int(roundedAverage)
    }
    
    ///Returns chance the playing Team has the top ranked card of the suit of the card being evaluated
    private func chanceTeamHasSuitTopRank(card: Card, suitTopRank: Int, following: Set<Seat>) -> Double {
        // For the card
        let validSuit = game.round.currentTrick.isEmpty
            || card.suit == game.round.currentTrick.leadSuit
            || (game.round.trump.isCalled && card.suit == game.round.trump.card?.suit)
        
        let winningRank = (card.currentRank > suitTopRank
                            || game.round.currentTrick.seatActions.count == 3)
            && card.currentRank > game.round.currentTrick.winningRank
        
        let cardWins = validSuit && winningRank
        
        if cardWins {
            return 1
        }
        // For the partner
        else {
            let partnerCanPlay = following
                .subtracting(game.round.seatsKnownEmptyForSuit[card.suit]!)
                .contains(activeCPUSeat!.partner)
            
            let topRankNotInHandAlreadyPlayed = game.round.currentTrick.winningRank > suitTopRank
            
            // If partner already played
            if !partnerCanPlay {
                // If top rank played already either it was your partner or not
                if topRankNotInHandAlreadyPlayed
                    && game.round.currentTrick.winningSeat == activeCPUSeat!.partner {
                    return 1
                }
                else {
                    return 0
                }
            }
            // If partner can still play
            else {
                // Top rank
                let topRankIsSeatsHiddenTrump: Bool = (
                    !game.round.trump.isCalled
                        && isBidder
                        && game.round.trump.card!.suit == card.suit
                        && game.round.trump.card!.currentRank > suitTopRank
                )
                
                if !topRankIsSeatsHiddenTrump && !topRankNotInHandAlreadyPlayed {
                    let remainingOppsNotEmpty = Double(
                        following
                            .subtracting(game.round.seatsKnownEmptyForSuit[card.suit]!)
                            .filter { $0.partnerGroup != activeCPUSeat!.partnerGroup}
                            .count
                    )
                    return 1 / ( 1 + remainingOppsNotEmpty)
                }
                else {
                    return 0
                }
            }
        }
    }
    
    ///Returns chance the playing Team has the top ranked card of the suit of the card being evaluated
    private func chanceOppHigherTrumpThanPartner(seat: Seat, following: Following, topRank: Int) -> Double {
        let knownTrump = trumpIsKnowntoPlayer(seat)
        var opTrumps: Int {
            if knownTrump {
                return following.seats_OfGroup_Not_EmptyofSuit(
                    seat.partnerGroup.opposingTeam,
                    game.round.trump.card!.suit
                ).count
            }
            else {
                return following.seatsofGroup(seat.partnerGroup.opposingTeam).count
            }
        }
        
        var partnerTrumps: Int {
            if knownTrump {
                return following.seats_OfGroup_Not_EmptyofSuit(
                    seat.partnerGroup,
                    game.round.trump.card!.suit
                ).count
            }
            else {
                return following.seatsofGroup(seat.partnerGroup).count
            }
        }
        
        // So long as top trump hasn't been played already, or no opponents left to play calculated the chance that opponent has trump
        if (knownTrump && topRank < game.round.currentTrick.winningRank) || opTrumps == 0 {
            return 0
        }
        // If no partner then 100% chance
        else if partnerTrumps == 0 {
            return 1
        }
        // opponents / partner + opponents
        else {
            return Double(opTrumps) / ( 1.0 + Double(opTrumps))
        }
    }
    
    
    private func otherPlayerCards() -> [Card] {
        var cards = game.round.hands.remainingCardsExcludingSeat(activeCPUSeat!)
        if game.round.trump.bidder != activeCPUSeat && !game.round.trump.isCalled {
            cards.append(game.round.trump.card!)
        }
        return cards
    }
    
    /// Returns an analysis for each suit of for each team, the chance of winning and the expected points won or lost
    private func getSuitAnalysis(
        for seat: Seat,
        following: Following,
        eligible suits: Set<Suit>,
        otherHandsCards: OtherHands
    ) ->  BestSuitToPlayAnalysis {
        // Guard last in trick
        guard game.round.currentTrick.seatActions.count != 3 else { return BestSuitToPlayAnalysis() }
        
        let remainingCards = otherPlayerCards()
        let remainingHonorCards = remainingCards.filter { $0.face.points > 0 }
        
        // Set properties for the trump known to the player
        let trumpKnown = trumpIsKnowntoPlayer(seat)
        let trump = game.round.trump.card!.suit
        
        
        var expectedPointsForTrump = [ PartnerGroup : ExpectedPoints ]()
        
        if trumpKnown && otherHandsCards[trump]!.count > 0 {
            expectedPointsForTrump = expectedPointsForPooledHands(
                population: remainingCards.count,
                suit: trump,
                honorCards: remainingHonorCards.filter { $0.suit == trump },
                following: following)
        }
        
        // Iterate over the suits in the player hand that are eligible to play
        var suitAnalysis = BestSuitToPlayAnalysis()
        for suit in suits {
            let suitCount = otherHandsCards[suit]!.count
            
            // The expected point for each partner group for the given suit
            let expectedPointsIfPlayingSuit = expectedPointsForPooledHands(
                population: remainingCards.count,
                suit: suit,
                honorCards: remainingHonorCards.filter { $0.suit == suit },
                following: following
            )
            
            var expectedPointsIfCutting = [ PartnerGroup : ExpectedPoints ]()
            if trumpKnown {
                expectedPointsIfCutting = expectedPointsForTrump
            }
            else {
                let averageExpectedPoints = getAvgHonorPointsInOtherHandsExcluding(
                    player: seat,
                    lead: suit,
                    trump: nil)
                
                expectedPointsIfCutting[.player] = averageExpectedPoints
                expectedPointsIfCutting[.opponent] = averageExpectedPoints
            }
            
            let expectedPointsIfEmptyofTrump = getAvgHonorPointsInOtherHandsExcluding(
                player: seat,
                lead: suit,
                trump: trump
            )
            
            // Estimate of remaining trumps in other hands is either known or estimated based on expected distrubution of suit cards
            var trumpCount: Int = 0
            if trumpKnown {
                trumpCount = otherHandsCards[trump]!.count
            }
            else {
                trumpCount = expectedTrumpCountWhenPlayingSuit(
                    suit: suit,
                    remainingSuitCards: otherHandsCards
                )
            }
            
            
            // Then iterate over the teams yet to play in the trick
            var teamEvaluations = TeamsEvaluations()
            for team in PartnerGroup.allCases {
                // Knowledge of the state of ability of a seat to trump is contained in the following sets
                let followingTeamSeats = following.seatsofGroup(team)
                
                // If no-one in this team set team values to zero and continue the loop
                if followingTeamSeats.isEmpty {
                    teamEvaluations[team] = SuitEvaluation()
                    continue
                }
                
                // For the trump
                var knownHasTrump = Set<Seat>()
                if !game.round.trump.beenPlayed {
                    // Only one seat can have the unplayed round trump
                    knownHasTrump = followingTeamSeats.intersection([game.round.trump.bidder!])
                }
                
                var knownEmptyOfTrumps = Set<Seat>()
                if trumpCount != 0 {
                    knownEmptyOfTrumps = following.seats_OfGroup_EmptyofSuit(team, trump)
                }
                else {
                    knownEmptyOfTrumps = followingTeamSeats
                }
                
                // So unknown is the team less the knowns
                let unknownHasTrump: Set<Seat> = followingTeamSeats
                    .subtracting(knownHasTrump)
                    .subtracting(knownEmptyOfTrumps)
                
                // Used for the denominator for expected point = hasTrumps + unknownHasTrumps
                let notKnownEmptyOfTrumps: Set<Seat> = followingTeamSeats
                    .subtracting(knownEmptyOfTrumps)
                
                // For the lead suit
                var knownEmptyOfSuit = Set<Seat>()
                if suitCount != 0 {
                    knownEmptyOfSuit = following.seats_OfGroup_EmptyofSuit(team, suit)
                }
                else {
                    knownEmptyOfSuit = followingTeamSeats
                }
                
                
                let unKnownIfEmpty: Set<Seat> = following.seats_OfGroup_Not_EmptyofSuit(team, suit)
                
                // From this knowledge we get four discrete sets without overlap where trumping is possible
                let knownCanCutAndEmptyTrumps = knownEmptyOfSuit.intersection(knownEmptyOfTrumps)
                let knownCanCutAndHasTrump = knownEmptyOfSuit.intersection(knownHasTrump)
                let knownCanCutAndUnknownHasTrump = knownEmptyOfSuit.intersection(unknownHasTrump)
                let unknownCanCutIsEmptyTrumps = unKnownIfEmpty.intersection(knownEmptyOfTrumps)
                let unknownCanCutAndHasTrumps = unKnownIfEmpty.intersection(knownHasTrump)
                let unknownCanCutOrHasTrump = unKnownIfEmpty.intersection(unknownHasTrump)
                
                
                // Chance for single hand cutting in the group that has a pooled chance to cut
                var singleUnknownCutChance: Double {
                    
                    let chanceOneHandEmpty = hyperGeoProb(
                        success: 0,
                        successPopulation: suitCount,
                        sample: handSize,
                        population: remainingCards.count)
                    
                    // As the chance of a cut is calculated as #unknownHands * singleChanceCut
                    // then if both are unknown we need to eliminate the % overlapping possibility
                    // that both unknown hands can cut
                    if unKnownIfEmpty.count == 2 {
                        let chanceBothEmpty = hyperGeoProb(
                            success: 0,
                            successPopulation: suitCount,
                            sample: handSize * 2,
                            population: remainingCards.count)
                        
                        return  chanceOneHandEmpty - ( chanceBothEmpty / 2 )
                    }
                    else {
                        return chanceOneHandEmpty
                    }
                }
                
                // Combining the probabilities for each discrete set
                var suitEvaluation = SuitEvaluation()
                
                if knownCanCutAndEmptyTrumps.count > 0 {
                    // Playing a card other than a suit or trump
                    suitEvaluation.expectedPoints.losing +=
                        expectedPointsIfEmptyofTrump.losing
                        * Double(knownCanCutAndEmptyTrumps.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        expectedPointsIfEmptyofTrump.winning
                        * Double(knownCanCutAndEmptyTrumps.count)
                }
                
                if unknownCanCutIsEmptyTrumps.count > 0 {
                    let chanceEmptyOfSuit =
                        singleUnknownCutChance
                        * Double(unknownCanCutIsEmptyTrumps.count)
                    
                    // When playing a card not a trump or a lead
                    suitEvaluation.expectedPoints.losing +=
                        chanceEmptyOfSuit
                        * expectedPointsIfEmptyofTrump.losing
                        * Double(unknownCanCutIsEmptyTrumps.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        chanceEmptyOfSuit
                        * expectedPointsIfEmptyofTrump.winning
                        * Double(unknownCanCutIsEmptyTrumps.count)
                    
                    // When playing a lead
                    suitEvaluation.expectedPoints.losing +=
                        (1 - chanceEmptyOfSuit)
                        * expectedPointsIfPlayingSuit[team]!.losing
                        * Double(unknownCanCutIsEmptyTrumps.count)
                        / Double(unKnownIfEmpty.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        (1 - chanceEmptyOfSuit)
                        * expectedPointsIfPlayingSuit[team]!.winning
                        * Double(unknownCanCutIsEmptyTrumps.count)
                        / Double(unKnownIfEmpty.count)
                }
                
                if knownCanCutAndHasTrump.count > 0 {
                    suitEvaluation.trumpChance += 1
                    
                    //Assume will always play the trump when cutting as definitely has trumps (this may not be true in reality if chance of winning is low)
                    suitEvaluation.expectedPoints.losing +=
                        expectedPointsIfCutting[team]!.losing
                        / Double(knownCanCutAndHasTrump.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        expectedPointsIfCutting[team]!.winning
                        / Double(knownCanCutAndHasTrump.count)
                }
                
                if unknownCanCutAndHasTrumps.count > 0 {
                    let chanceEmptyOfSuit = singleUnknownCutChance
                        * Double(unknownCanCutAndHasTrumps.count)
                    
                    suitEvaluation.trumpChance += chanceEmptyOfSuit
                    
                    //Assume will always play the trump when cutting as definitely has trumps (this may not be true in reality if chance of winning is low)
                    suitEvaluation.expectedPoints.losing +=
                        chanceEmptyOfSuit
                        * expectedPointsIfCutting[team]!.losing
                        * Double(unknownCanCutAndHasTrumps.count)
                        / Double(notKnownEmptyOfTrumps.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        chanceEmptyOfSuit
                        * expectedPointsIfCutting[team]!.winning
                        * Double(unknownCanCutAndHasTrumps.count)
                        / Double(notKnownEmptyOfTrumps.count)
                    
                    // For chance has suit
                    suitEvaluation.expectedPoints.losing +=
                        (1 - chanceEmptyOfSuit)
                        * expectedPointsIfPlayingSuit[team]!.losing
                        * Double(unknownCanCutAndHasTrumps.count)
                        / Double(unKnownIfEmpty.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        (1 - chanceEmptyOfSuit)
                        * expectedPointsIfPlayingSuit[team]!.winning
                        * Double(unknownCanCutAndHasTrumps.count)
                        / Double(unKnownIfEmpty.count)
                }
                
                if knownCanCutAndUnknownHasTrump.count > 0 {
                    let chanceHasTrump = 1 - hyperGeoProb(
                        success: 0,
                        successPopulation: trumpCount,
                        sample: handSize * knownCanCutAndUnknownHasTrump.count,
                        population: remainingCards.count - handSize)
                    
                    suitEvaluation.trumpChance += chanceHasTrump
                    
                    //Assume will always play the trump if have trumps (this may not be true in reality if chance of winning is low)
                    suitEvaluation.expectedPoints.losing +=
                        chanceHasTrump
                        * expectedPointsIfCutting[team]!.losing
                        * Double(knownCanCutAndUnknownHasTrump.count)
                        / Double(notKnownEmptyOfTrumps.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        chanceHasTrump
                        * expectedPointsIfCutting[team]!.winning
                        * Double(knownCanCutAndUnknownHasTrump.count)
                        / Double(notKnownEmptyOfTrumps.count)
                    
                    // For chance empty of trump (and lead as can cut)
                    suitEvaluation.expectedPoints.losing +=
                        (1 - chanceHasTrump)
                        * expectedPointsIfEmptyofTrump.losing
                        * Double(knownCanCutAndUnknownHasTrump.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        (1 - chanceHasTrump)
                        * expectedPointsIfEmptyofTrump.winning
                        * Double(knownCanCutAndUnknownHasTrump.count)
                }
                
                if unknownCanCutOrHasTrump.count > 0 {
                    let chanceCut =
                        singleUnknownCutChance
                        * Double(unknownCanCutOrHasTrump.count)
                    
                    let chanceHasTrumps = (1 - hyperGeoProb(
                                            success: 0,
                                            successPopulation: trumpCount,
                                            sample: handSize * unknownCanCutOrHasTrump.count,
                                            population: remainingCards.count - handSize ))
                    
                    suitEvaluation.trumpChance += chanceCut * chanceHasTrumps
                    
                    // Chances of suit of lead being (again using loose assumption that will play trumps when cutting if they have them)
                    let chancePlaysLeadCard = (1 - chanceCut)
                    let chancePlaysTrump = chanceCut * chanceHasTrumps
                    let chancePlaysNeither = chanceCut * (1 - chanceHasTrumps)
                    
                    // When playing lead suit
                    suitEvaluation.expectedPoints.losing +=
                        chancePlaysLeadCard
                        * expectedPointsIfPlayingSuit[team]!.losing
                        * Double(unknownCanCutOrHasTrump.count)
                        / Double(unKnownIfEmpty.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        chancePlaysLeadCard
                        * expectedPointsIfPlayingSuit[team]!.winning
                        * Double(unknownCanCutOrHasTrump.count)
                        / Double(unKnownIfEmpty.count)
                    
                    // When playing trump
                    suitEvaluation.expectedPoints.losing +=
                        chancePlaysTrump
                        * expectedPointsIfCutting[team]!.losing
                        * Double(unknownCanCutOrHasTrump.count)
                        / Double(notKnownEmptyOfTrumps.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        chancePlaysTrump
                        * expectedPointsIfCutting[team]!.winning
                        * Double(unknownCanCutOrHasTrump.count)
                        / Double(notKnownEmptyOfTrumps.count)
                    
                    // When playing neither
                    suitEvaluation.expectedPoints.losing +=
                        chancePlaysNeither
                        * expectedPointsIfEmptyofTrump.losing
                        * Double(unknownCanCutOrHasTrump.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        chancePlaysNeither
                        * expectedPointsIfEmptyofTrump.winning
                        * Double(unknownCanCutOrHasTrump.count)
                }
                
                if suitEvaluation.expectedPoints.losing.isNaN || suitEvaluation.expectedPoints.losing.isNaN {
                    print("Not a number")
                }
                
                teamEvaluations[team] = suitEvaluation
            }
            suitAnalysis[suit] = teamEvaluations
        }
        return suitAnalysis
    }
    
    /// Returns the hypergeometric probability  Px(k)  that a a sample of n, from a population N that contains K results of the defined success state,  contains  k events  of the  defined success state.
    private func hyperGeoProb(
        success k: Int,
        successPopulation K: Int,
        sample n: Int,
        population N: Int)
    -> Double {
        // Early return if success is greater than sample as clearly can not happen
        if (n - k) < 0 { return 0 }
        // Combinations of choosing success from success pop : K Choose k
        let comA = factorial(K) / ( factorial(k) * factorial(K-k) )
        
        // Combinations selection of non-Success (n-k) from  non-Success Population : (N-K) Choose (n-k)
        let nonSuccessPop = N - K
        let nonSuccessSelected = min(n - k, nonSuccessPop) // Can't have more selected than the pop size
        
        let comB = factorial(nonSuccessPop)
            / ( factorial(nonSuccessSelected) * factorial(nonSuccessPop - nonSuccessSelected))
        
        // Total combination of selecting n from total population : N Choose n
        let comC = factorial(N) / ( factorial(n) * factorial(N-n) )
        
        // The probability of the event
        let probabilityK = comA * comB / comC
        return probabilityK
    }
    
    /// Returns a Double factorial from given card count Int
    private func factorial(_ n: Int) -> Double {
        // Hacked to avoid recalc every time for common limited set of factorials used in game
        assert(n >= 0 && n < 33, "Error - factorial not in card count range")
        return factorials32[n]
    }
    
    /// The expected average value for the first value in an array passed into it of remaining honors (if winning sort high to low, if losing low to high) for a assumed array of honorCards
    private func expectedPointPerCardsInHandsState(honorCards: [Card], winning: Bool) -> [Double] {
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
    
    /// Returns for each partner group the expected points total if that group where expecting to win or lose fro the remaining cards to be played in a trick
    private func expectedPointsForPooledHands(population: Int, suit: Suit, honorCards: [Card], following: Following)
    -> [PartnerGroup : ExpectedPoints] {
        
        var pointsByGroup: [PartnerGroup : ExpectedPoints] = [
            .opponent : ExpectedPoints(),
            .player : ExpectedPoints()
        ]
        
        // Early return if no honor cards or following seats
        if honorCards.count == 0 || following.seats.isEmpty  { return pointsByGroup }
        
        let winningPoints = expectedPointPerCardsInHandsState(honorCards: honorCards, winning: true)
        let losingPoints = expectedPointPerCardsInHandsState(honorCards: honorCards, winning: false)
        
        
        for group in PartnerGroup.allCases {
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
                    population: population)
                
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
                    
                    denominator = Double(opponentCardCountPairs.count)
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
}
