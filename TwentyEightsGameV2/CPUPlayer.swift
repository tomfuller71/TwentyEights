//
//  CPUPlayer.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/10/21.
//

import Foundation
import Combine

class CPUPlayer {
    private(set) var game: GameController
    private(set) var seat: Seat
    
    var otherHandsAnalysis: OtherHandsAnalysis
    var following: Following
    var factorials32: [Double] = []
    
    private var activeCancellable: AnyCancellable?
    
    init(game: GameController) {
        self.game = game
        self.seat = game.starting
        
        self.otherHandsAnalysis = OtherHandsAnalysis(seat: self.seat, cards: [], trump: Trump())
        self.following = Following(seats: Set(Seat.allCases), emptySuits: game.round.seatsKnownEmptyForSuit)
        self.factorials32 = CPUPlayer.getFirst32Factorials()
        
        self.activeCancellable = self.game.$active.sink { seat in
            if self.game.players[seat]!.playerType == .localCPU {
                self.seat = seat
                self.takeAction()
            }
        }
    }
    
    private class func getFirst32Factorials() -> [Double] {
        var facts: [Double] = []
        for  i in 0 ... 32 {
            let fact =  i > 0 ? (1 ... i).map(Double.init).reduce(1.0, *)  :  1
            facts.append(fact)
        }
        return facts
    }
}

//MARK: - CPU Player action
extension CPUPlayer {
    private func takeAction() {
        let actionType: PlayerAction.ActionType =  getAction()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay) {
            self.game.respondToPlayerAction(
                PlayerAction(seat: self.seat, type: actionType)
            )
        }
    }
    /// Returns the next action for the activeCPU to take
    private func getAction() -> PlayerAction.ActionType {
        if isBidding {
            let suggestedBid = selectBestBid()
            
            if let bid = suggestedBid {
                return .makeBid(bid)
            }
            else {
                return .pass(stage: game.round.bidding.stage)
            }
        }
        // Otherwise play in trick
        else {
            
            // Set analysis structures used in playing in trick
            otherHandsAnalysis = OtherHandsAnalysis(
                seat: seat,
                cards: game.round.hands.remainingCardsExcludingSeat(seat),
                trump: trump
            )
            
            following = Following(
                seats: currentTrick.followingSeats,
                emptySuits: game.round.seatsKnownEmptyForSuit
            )
            
            if seatShouldCallTrump() {
                return .callForTrump
            }
            else {
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
        }
    }
}


// MARK:- Commmon computed properties & methods
extension CPUPlayer {
    /// True if the game is currently in either the first or second stage of bidding
    var isBidding: Bool {
        if case .bidding(_) = game.round.stage { return true } else { return false }
    }
    
    /// Current hand size for the AI player
    var handSize: Int { _28s.initalHandSize - game.round.trickCount }
    
    /// Returns true is the provided Seat is the bidder
    var isBidder: Bool {
      seat == game.round.bidding.winningBid?.bidder
    }
    
    /// Returns true if the provided card is the same suit as the trump card
    func isTrumpSuit(_ card: Card) -> Bool {
        card.suit == trump.suit
    }
    
    var trumpKnown: Bool {
        trump.isCalled || isBidder
    }
    
    var trumpEmpty: Bool {
        trumpKnown && otherHandsAnalysis.suits[trump.suit!]?.count == 0
    }
    
    // Using below to convienience to shorten property lengths
    var currentTrick: Trick {
        game.round.currentTrick
    }
    
    var trump: Trump {
        game.round.trump
    }
}


//MARK: - AI Bidding
extension CPUPlayer {
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
        let minBid: Int = game.round.bidding.bidMinForSeat(seat)
        
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
        seat != game.round.starting || game.round.bidding.winningBid != nil
    }
    
    /// Determine a suggested bid
    private func suggestBid() -> Bid {
        let hand = game.round.hands[seat]
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
        
        return Bid(points: bidpoints, card: selectedCard, bidder: seat)
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
    //MARK: - AI call for trump
    private func seatShouldCallTrump() -> Bool {
        // Early return if can't call
        guard game.round.canSeatCallTrump(seat) else {
            return false
        }
        
        // Tests used in switch case determing whether to call
        let cpuTeam = seat.team
        
        var partnerIsWinning: Bool { currentTrick.winningSeat?.team == cpuTeam }
        
        var winningRankHigherThanTopRemaining: Bool {
            otherHandsAnalysis.suits[currentTrick.leadSuit!]!.topRank < currentTrick.winningRank
        }
        
        var cpuTeamIsBidder: Bool  { trump.bidder?.team == cpuTeam }
        var noPointsInTrick: Bool { currentTrick.pointsInTrick == 0 }
        
        var followingEmptyOfLead: Bool {
            game.round.seatsKnownEmptyForSuit[currentTrick.leadSuit!]!
            .contains(seat.nextSeat())
        }
        
        var onlyHaveHonorsLeftInHand: Bool {
            game.round.hands[seat]
                .filter { $0.face.points == 0 }
                .count == 0
        }
        
        // Game logic of cpu Call / No call decision
        switch game.round.currentTrick.seatActions.count {
        case 1:
            return true
            
        case 2:
            if partnerIsWinning && winningRankHigherThanTopRemaining && !followingEmptyOfLead && !cpuTeamIsBidder {
                print("Not calling as partner winning with top card, following players aren't empty of lead and not bidding team")
                return false
            }
            else if noPointsInTrick && otherHandsAnalysis.suits[currentTrick.leadSuit!]!.honorPoints == 0 && !onlyHaveHonorsLeftInHand {
                print("Not calling as no points in trick, no remaining lead honors and don't only have honor left in hand")
                return false
            }
            else {
                return true
            }
            
        case 3:
            if partnerIsWinning && !cpuTeamIsBidder {
                print("Not calling as partner is winning and not the bidding team")
                return false
            }
            else {
                return true
            }
            
        default:
            print("Error - invalid count of seatActions")
            return false
        }
        
    }
}



extension CPUPlayer {
    //MARK: - AI Playing in Trick
    /*
     - The best card to play is the one that yields the highest EV of honor points for the team.
     
     - Rather than reflowing the card evaluation for all subsequent tricks to get a true EV
     the app uses pseudo-logic to evaluate the best card to play given the EV for the current
     trick coupled with rules of thumb of the best card to play when certain to lose / could win
     
     - The net EV of any given card is the the expected trick Value if a winner minus the expected trick Value if a loser
     
     - The EV winning is the chance of team winning * the estimated honor points in a trick in which it is assumed the opponent will limit their point lost
     
     - The EV losing is the chance of team losing * the estimated honor points in a trick where it is assumed that the partner will limit their points lost
     
     - The chance of winning is a simple estimation that assumes that topRank card needed to win will have been played early in the round if it was available (no-finessing)
         unless the player is last to play and it is clear what the winning rank was not played
     
     - Chance of being trumped is probability based on knowledge the player of:
        - the number of players yet to play in trick,
        - the trump suit if known to the player,
        - whether any remaining players are known to be empty of the eligible cards suit,
        - the maximum number of trump cards remaining,
        - whether any remaining players in the trick don't have trumps,
        - if the top trump cards has already been played
     
     - The "winning" chance = (chance of Team Having Top rank and not being trumped by anyone) + (chance Team itself Trumps and the opponent doesn't overtrump)
     */
    
    /// Return the best card to play from an array of cards that are eligible to play, if reRun is true then we are calc the chance of next best card leading off the trick
    private func selectBestCardToPlay(from eligibleCards: [Card]) -> Card {
        let eligibleProbsAndPoints = getCardEvaluations(from: eligibleCards)
            .sorted {
                if ($0.netExpectedPoints, $0.winChance) != ($1.netExpectedPoints, $1.winChance) {
                    return ($0.netExpectedPoints, $0.winChance) > ($1.netExpectedPoints, $1.winChance)
                }
                else {
                    return $0.card.currentRank < $1.card.currentRank
                }
            }
        
        // State of card with best EV
        var bestCard = eligibleProbsAndPoints[0].card
        
        // Early return if playing first in trick
        guard !currentTrick.isEmpty else { return bestCard }
        
        // Otherwise select the best card to play based on ...
        let certainToLose = eligibleProbsAndPoints[0].winChance <= 0
        let certainToWin = eligibleProbsAndPoints[0].winChance >= 1
        let dumpingNonTrump = !currentTrick.isEmpty && bestCard.suit != currentTrick.leadSuit!
            && !(trump.isCalled && bestCard.suit == trump.suit!)
        
        
        // Selection logic
        if certainToLose || dumpingNonTrump {
            bestCard = bestCertainLosingCard(from: eligibleProbsAndPoints)
        }
        else if certainToWin {
            bestCard = bestCertainWinningCard(from: eligibleProbsAndPoints)
        }
        
        return bestCard
    }
    
    
    /// Returns the card which is best to play if all cards are certain to lose the trick
    private func bestCertainLosingCard(from eligibleProbsAndPoints: [CardEvaluation]) -> Card {
        
        /*If certain to lose:
         - try and keep back top ranked cards of their suit, unless suit known cuttable
         - otherwise play the first card recommendation
         */
        
        let nonTopRankCards = eligibleProbsAndPoints.filter {
            !topRankNotKnownEmpty(
                card: $0.card,
                suitTopRank: otherHandsAnalysis.suits[$0.card.suit]!.topRank)
        }
        
        if let best = nonTopRankCards.first?.card {
            print("Certain to lose - playing non-top Rank Card not know cuttable")
            return best
        }
        else {
            print("Certain to lose - playing first recommended card")
            return eligibleProbsAndPoints.first!.card
        }
    }
    
    /// Returns the best card to play that is certain to win
    private func bestCertainWinningCard(from eligibleProbsAndPoints: [CardEvaluation]) -> Card {
        
        /*If certain to win try and play in order:
             i) any winning 'shake' honors in hand of the suit that are not unbeatable in future tricks
             ii) highest EV certain winner that is not unbeatable non top rank in future tricks
             iii) the highest EV card that isn't unbeatable
             iv) the highest EV (first recommended) card
         */
            
            let first = eligibleProbsAndPoints[0].card
            let certainWinners = eligibleProbsAndPoints.filter { $0.winChance >= 1 }
            
            let winnersExcludingUnbeatable: [CardEvaluation] = certainWinners.isEmpty ? [] :
            excludeUnbeatableCardEvalutions(from: certainWinners)
            
            if !winnersExcludingUnbeatable.isEmpty {
                let soleHonors = winnersExcludingUnbeatable.filter {
                    game.round.hands.hasSoleHonorCard(seat: seat, suit: $0.card.suit)
            }
            
            if let best = soleHonors.first?.card {
                print("Playing beatable sole honor")
                return best
            }
            else {
                let excludingTopRankNotKnowCuttable = winnersExcludingUnbeatable.filter {
                    !topRankNotKnownEmpty(
                        card: $0.card,
                        suitTopRank: otherHandsAnalysis.suits[$0.card.suit]!.topRank)
                }
                
                if let best = excludingTopRankNotKnowCuttable.first?.card {
                    print("Playing winner excluding unbeatable and top ranked cards of suit not known cuttable")
                    return best
                }
                else {
                    print("Playing highest EV excluding unbeatable cards")
                    return winnersExcludingUnbeatable.first!.card
                }
            }
        }
        else {
            print("No unbeatable or top-rank card that aren't known cuttable - so playing first certain winner")
            return first
        }
    }
    
    /// Returns true if given seat not known to be empty of the given suit
    private func seatKnownEmptyOfSuit(_ seat: Seat, _ suit: Suit) -> Bool {
        game.round.seatsKnownEmptyForSuit[suit]!.contains(seat)
    }
    
    
    /// Returns an array of card evlautions that excludes any  for cards that would be unbeatable if played in a future trick
    private func excludeUnbeatableCardEvalutions(from evaluations: [CardEvaluation]) -> [CardEvaluation] {
        
        guard trumpKnown else { return [] }
        
        return evaluations.filter { eval in
            let opponentsEmptyTrumps = seat.team.opposingTeam.teamMembers
                .filter { !seatKnownEmptyOfSuit($0, trump.suit!) }
                .isEmpty
            
            // If can't be trumped include in return if not the top rank( as beatable)
            if trumpEmpty || opponentsEmptyTrumps ||  eval.card.suit == trump.suit! {
                return eval.card.currentRank < otherHandsAnalysis.suits[eval.card.suit]!.topRank
            }
            // If can be trumped include in return as not unbeatable
            else {
                return true
            }
        }
    }

    /// Returns true if a given card is the top rank of its suit and the suit is not known to be cut/trump-able
    private func topRankNotKnownEmpty(card: Card, suitTopRank: Int) -> Bool {
        
        let opposingTeamNotKnownCuttable: Bool = seat.team.opposingTeam.teamMembers
            .filter {
                var knownAbleToCut = seatKnownEmptyOfSuit($0, card.suit)
                if trumpKnown && seatKnownEmptyOfSuit($0, trump.suit!) {
                    knownAbleToCut = false
                }
                return knownAbleToCut
            }
            .isEmpty
        // True if card is the top rank and either no trumps left or opposing team not known able to cut
        return card.currentRank > suitTopRank && (trumpEmpty || opposingTeamNotKnownCuttable)
    }
    
    /// Returns a set of Card Evaluations for each card in the players hand that is eligible to play, for a given seat, given the `OtherHands` knowledge
    private func getCardEvaluations(from eligibleCards: [Card]) -> [CardEvaluation] {
        
        // Eligible suits
        var eligibleSuits: Set<Suit> = Set(eligibleCards.map { $0.suit })
        if let leadSuit = currentTrick.leadSuit {
            eligibleSuits.insert(leadSuit)
        }
        else if trumpKnown {
            eligibleSuits.insert(trump.suit!)
        }
        
        // For each eligible suit, and team, get chance that a card of suit would be trumped by the team, and the expected points value of the card(s) played by the team
        let suitAnalysis: BestSuitToPlayAnalysis = getSuitAnalysis(eligible: eligibleSuits)
        
        // Get the chance that an opponent has a higher trump than your partner
        let trumpTopRank: Int = otherHandsAnalysis.suits[trump.suit!]!.topRank
        let chanceOpTrumpHigher: Double =  chanceOppHigherTrumpThanPartner(topRank: trumpTopRank)
        
        // Get the array of probabilities for each card
        var cardProbabilities: [CardEvaluation] = []
        
        for card in eligibleCards {
            // Determine relevant suit
            let suit = currentTrick.isEmpty ? card.suit : currentTrick.leadSuit!
            
            // Determine chance the player team has the top ranked card that could win a trick if not trumped
            let chanceTeamTopRank = chanceTeamHasSuitTopRank(
                card: card,
                suitTopRank: otherHandsAnalysis.suits[suit]!.topRank
            )
            
            // Determine chance of card being trumped
            let canBeTrumped: Bool = !(
                trump.isCalled
                    && (card.currentRank > trumpTopRank || currentTrick.leadSuit == trump.suit)
            )
            
            var trumpChances = (partner: 0.0, opponent: 0.0)
            if canBeTrumped {
                trumpChances.partner = suitAnalysis[suit][seat.team].trumpChance
                trumpChances.opponent = suitAnalysis[suit][seat.team.opposingTeam].trumpChance
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
                    + suitAnalysis[suit][seat.team].expectedPoints.winning
                    + suitAnalysis[suit][seat.team.opposingTeam].expectedPoints.losing,
                
                // Partner trying to minimise pts opponent trying to maximise points
                losePoints: current
                    + suitAnalysis[suit][seat.team].expectedPoints.losing
                    + suitAnalysis[suit][seat.team.opposingTeam].expectedPoints.winning
            )
            
            if trickPointValue.winPoints == .nan || trickPointValue.losePoints == .nan {
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
                + " p: \(String(format: "%.1f%%", trumpChances.partner  * 100))"
                + " o: \(String(format: "%.1f%%", trumpChances.opponent  * 100))"
                + " p overT: \(String(format: "%.1f%%", chancePartnerOverTrumps * 100))"
                + " suitWin: \(String(format: "%.1f%%", chanceTeamTopRank * 100))"
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
            
            if (chanceTeamWinning > 1 || chanceTeamWinning < 0)
                || (chanceTeamTopRank > 1 || chanceTeamTopRank < 0)
                || (chanceOpTrumpHigher > 1 || chanceOpTrumpHigher < 0)
                || (chancePartnerOverTrumps > 1 || chancePartnerOverTrumps < 0)
                || (chancePartnerAloneTrumps > 1 || chancePartnerAloneTrumps < 0)
                || (chancePartnerCardTrumpsAndWins > 1 || chancePartnerCardTrumpsAndWins < 0)
                || (chanceTeamTopCardOfSuitWins > 1 || chanceTeamTopCardOfSuitWins < 0) {
                
                print("Error in probability")
            }
        }
        return cardProbabilities
    }
    
    /// Enumeration of types of action a follwoing seat could play
    enum CardAction: CaseIterable, Hashable {
        case playSuit, cut(trump: Bool?)
        
        static let allCases: [CardAction] = [
            .playSuit,
            .cut(trump: true),
            .cut(trump: false),
            .cut(trump: nil)
        ]
    }
    
    
    func potentialCardActions(for player: Seat, lead: Suit) -> [CardAction] {
        var cardActionOptions: [CardAction] = []
        
        // See playsuit suit to either the lead suit or trick leadSuit
        let playingSuit = currentTrick.isEmpty ? lead : currentTrick.leadSuit!
        
        // Assume can play lead suit unless known othrewise
        let canPlaySuit = !( otherHandsAnalysis.suits[playingSuit]!.count == 0
                             || following.seatsKnownEmptyForSuit[playingSuit]!.contains(player) )
        
        // Can always potentially cut, whether have trump is either known(true/false) or unknown nil
        var hasTrumps: Bool? = nil
        if trumpKnown {
            if ( trumpEmpty || game.round.seatsKnownEmptyForSuit[trump.suit!]!.contains(player) ) {
                hasTrumps = false
            }
            else if trump.bidder == player && !trump.beenPlayed {
                hasTrumps = true
            }
        }
        
        // Add viable card actions
        if canPlaySuit {
            cardActionOptions.append(.playSuit)
        }
        cardActionOptions.append(.cut(trump: hasTrumps))
        
        return cardActionOptions
    }
    

    
    
       
    /// Returns the average honor points per cards in the deck that excludes cards of the current player, and cards of  the lead suit and optionally the trumpSuit
    private func getAvgHonorPointsInOtherHandsExcluding(
        lead leadSuit: Suit,
        trump trumpsuit: Suit?
    ) -> ExpectedPoints {
        
        let nonSeatNonSuitCards = game.round.hands.remainingCardsExcludingSeat(seat)
            .filter { $0.suit != leadSuit || $0.suit != trumpsuit }
        
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
    
    /// The players expectation of the remaining number of unplayed Trumps ( used in determining probability of a card being trumped)
    private func expectedTrumpCountWhenPlayingSuit(
        suit: Suit,
        remainingSuitCards: [Suit : SuitAnalysis]
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
    private func chanceTeamHasSuitTopRank(card: Card, suitTopRank: Int) -> Double {
        
        let validSuit = currentTrick.isEmpty || card.suit == currentTrick.leadSuit
            || (trump.isCalled && card.suit == trump.suit)
        
        let rankToBeat = currentTrick.playerIsLastToPlay ? currentTrick.winningRank : suitTopRank
        
        let partnerWinnerIsTopRank = currentTrick.winningSeat == seat.partner
            && currentTrick.winningRank > suitTopRank
        
        let seatCardIsTopRank = validSuit && card.currentRank > rankToBeat
        
        // If seat or partner has top Rank then chance Top is certain
        if seatCardIsTopRank || partnerWinnerIsTopRank {
            return 1
        }
        // If partner can still play then chance to win
        else if game.round.seatsNotEmptyOf(card.suit, from: .following).contains(seat.partner) {
            let countOpponentsWhoCouldPlaySuit = Double(
                following.seats_OfGroup_Not_EmptyofSuit(seat.team.opposingTeam, card.suit)
                    .count
            )
            return 1 / ( 1 + countOpponentsWhoCouldPlaySuit)
        }
        // If neither seat nor partner top then assume certain to lose the trick
        else {
            return 0
        }
    }
    
    ///Returns chance the playing Team has the top ranked card of the suit of the card being evaluated
    private func chanceOppHigherTrumpThanPartner(topRank: Int) -> Double {
        var opTrumps: Int {
            if trumpKnown {
                return following.seats_OfGroup_Not_EmptyofSuit(
                    seat.team.opposingTeam,
                    trump.card!.suit
                ).count
            }
            else {
                return following.seatsOfTeam(seat.team.opposingTeam).count
            }
        }
        
        var partnerTrumps: Int {
            if trumpKnown {
                return following.seats_OfGroup_Not_EmptyofSuit(
                    seat.team,
                    trump.card!.suit
                ).count
            }
            else {
                return following.seatsOfTeam(seat.team).count
            }
        }
        
        // So long as top trump hasn't been played already, or no opponents left to play calculated the chance that opponent has trump
        if (trumpKnown && topRank < currentTrick.winningRank) || opTrumps == 0 {
            return 0
        }
        // opponents / partner + opponents
        else {
            return Double(opTrumps) / ( Double(partnerTrumps) + Double(opTrumps))
        }
    }
    
    
    /// Returns an analysis for each suit of for each team, the chance of winning and the expected points won or lost
    private func getSuitAnalysis(eligible suits: Set<Suit>) ->  BestSuitToPlayAnalysis {
        
        let population = otherHandsAnalysis.population
        
        var expectedPointsForTrump = [ Team : ExpectedPoints ]()
        if trumpKnown && otherHandsAnalysis.suits[trump.suit!]!.count > 0 {
            expectedPointsForTrump = expectedPointsForPooledHands(
                population: population,
                suit: trump.suit!,
                honorCards: otherHandsAnalysis.suits[trump.suit!]!.honorCards)
        }
        
        // Iterate over the suits in the player hand that are eligible to play
        var suitAnalysis = BestSuitToPlayAnalysis()
        for suit in suits {
            let suitCount = otherHandsAnalysis.suits[suit]!.count
            
            // The expected point for each partner group for the given suit
            let expectedPointsIfPlayingSuit = expectedPointsForPooledHands(
                population: population,
                suit: suit,
                honorCards: otherHandsAnalysis.suits[suit]!.honorCards
            )
            
            var expectedPointsIfCutting = [ Team : ExpectedPoints ]()
            if trumpKnown {
                expectedPointsIfCutting = expectedPointsForTrump
            }
            else {
                let averageExpectedPoints = getAvgHonorPointsInOtherHandsExcluding(lead: suit, trump: nil)
                
                expectedPointsIfCutting[.player] = averageExpectedPoints
                expectedPointsIfCutting[.opponent] = averageExpectedPoints
            }
            
            let expectedPointsIfEmptyofTrump = getAvgHonorPointsInOtherHandsExcluding(lead: suit, trump: trump.suit!)
            
            // Estimate of remaining trumps in other hands is either known or estimated based on expected distrubution of suit cards
            var trumpCount: Int = 0
            if trumpKnown {
                trumpCount = otherHandsAnalysis.suits[trump.suit!]!.count
            }
            else {
                trumpCount = expectedTrumpCountWhenPlayingSuit(
                    suit: suit,
                    remainingSuitCards: otherHandsAnalysis.suits
                )
            }
            
            
            // Then iterate over the teams yet to play in the trick
            var teamEvaluations = TeamsEvaluations()
            for team in Team.allCases {
                // Knowledge of the state of ability of a seat to trump is contained in the following sets
                let followingTeamSeats = following.seatsOfTeam(team)
                
                // If no-one in this team set team values to zero and continue the loop
                if followingTeamSeats.isEmpty {
                    teamEvaluations[team] = CutAndExpectedPoints()
                    continue
                }
                
                // For the trump
                var knownHasTrump = Set<Seat>()
                if !trump.beenPlayed {
                    // Only one seat can have the unplayed round trump
                    knownHasTrump = followingTeamSeats.intersection([trump.bidder!])
                }
                
                var knownEmptyOfTrumps = Set<Seat>()
                if trumpCount != 0 {
                    knownEmptyOfTrumps = following.seats_OfGroup_EmptyofSuit(team, trump.suit!)
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
                
                
                let unKnownIfEmptyOfSuit: Set<Seat> = followingTeamSeats
                    .subtracting(knownEmptyOfSuit)
                
                // From this knowledge we get discrete sets without overlap
                let knownCanCutAndEmptyTrumps = knownEmptyOfSuit.intersection(knownEmptyOfTrumps)
                let knownCanCutAndHasTrump = knownEmptyOfSuit.intersection(knownHasTrump)
                let knownCanCutAndUnknownHasTrump = knownEmptyOfSuit.intersection(unknownHasTrump)
                let unknownCanCutIsEmptyTrumps = unKnownIfEmptyOfSuit.intersection(knownEmptyOfTrumps)
                let unknownCanCutAndHasTrumps = unKnownIfEmptyOfSuit.intersection(knownHasTrump)
                let unknownCanCutOrHasTrump = unKnownIfEmptyOfSuit.intersection(unknownHasTrump)
                
                
                // Chance for single hand cutting in the group that has a pooled chance to cut
                var singleUnknownCutChance: Double {
                    let chanceOneHandEmpty = hyperGeoProb(
                        success: 0,
                        successPopulation: suitCount,
                        sample: handSize,
                        population: population)
                    
                    // As the chance of a cut is calculated as #unknownHands * singleChanceCut
                    // then if both are unknown we need to eliminate the % overlapping possibility
                    // that both unknown hands can cut
                    if unKnownIfEmptyOfSuit.count == 2 {
                        let chanceBothEmpty = hyperGeoProb(
                            success: 0,
                            successPopulation: suitCount,
                            sample: handSize * 2,
                            population: population)
                        
                        return  chanceOneHandEmpty - ( chanceBothEmpty / 2 )
                    }
                    else {
                        return chanceOneHandEmpty
                    }
                }
                
                // Combining the probabilities for each discrete set
                var suitEvaluation = CutAndExpectedPoints()
                
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
                        / Double(unKnownIfEmptyOfSuit.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        (1 - chanceEmptyOfSuit)
                        * expectedPointsIfPlayingSuit[team]!.winning
                        * Double(unknownCanCutIsEmptyTrumps.count)
                        / Double(unKnownIfEmptyOfSuit.count)
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
                        / Double(unKnownIfEmptyOfSuit.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        (1 - chanceEmptyOfSuit)
                        * expectedPointsIfPlayingSuit[team]!.winning
                        * Double(unknownCanCutAndHasTrumps.count)
                        / Double(unKnownIfEmptyOfSuit.count)
                }
                
                if knownCanCutAndUnknownHasTrump.count > 0 {
                    let chanceHasTrump = 1 - hyperGeoProb(
                        success: 0,
                        successPopulation: trumpCount,
                        sample: handSize * knownCanCutAndUnknownHasTrump.count,
                        population: population)
                    
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
                                            population: population))
                    
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
                        / Double(unKnownIfEmptyOfSuit.count)
                    
                    suitEvaluation.expectedPoints.winning +=
                        chancePlaysLeadCard
                        * expectedPointsIfPlayingSuit[team]!.winning
                        * Double(unknownCanCutOrHasTrump.count)
                        / Double(unKnownIfEmptyOfSuit.count)
                    
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
                
                if suitEvaluation.trumpChance > 1 || suitEvaluation.trumpChance < 0 {
                    print(" Bad Trump Chance probability")
                }
                
                teamEvaluations[team] = suitEvaluation
            }
            suitAnalysis[suit] = teamEvaluations
        }
        return suitAnalysis
    }
    
    /// Returns the hypergeometric probability  Px(k)  that a a sample of n, from a population N that contains K results of the defined success state,  contains  k events  of the  defined success state.
   func hyperGeoProb(
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
    func factorial(_ n: Int) -> Double {
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
    
    /// Returns for each partner group the expected points total if that group where expecting to win or lose for the remaining cards to be played in a trick
    private func expectedPointsForPooledHands(population: Int, suit: Suit, honorCards: [Card])
    -> [Team : ExpectedPoints] {
        
        var pointsByGroup: [Team : ExpectedPoints] = [
            .opponent : ExpectedPoints(),
            .player : ExpectedPoints()
        ]
        
        // Early return if no honor cards or following seats
        if honorCards.count == 0 || following.seats.isEmpty  { return pointsByGroup }
        
        let winningPoints = expectedPointPerCardsInHandsState(honorCards: honorCards, winning: true)
        let losingPoints = expectedPointPerCardsInHandsState(honorCards: honorCards, winning: false)
        
        
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
