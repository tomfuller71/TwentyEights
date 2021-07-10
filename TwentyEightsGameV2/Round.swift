//
//  Round.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 2/26/21.
//

import Foundation

/// Data model for one round of 28s
struct Round {
    //MARK: Round properties
    let starting: Seat
    var hands: RoundCards = RoundCards()
    var stage: RoundStage = .starting { willSet { dealCardsOnStageUpdate(newValue) } }
    var actions: [PlayerAction] = []
    var bidding: Bidding = Bidding()
    var trump = Trump()
    //var topBid: (points: Int, seat: Seat?) = (points: 0, seat: nil)
    var currentTrick: Trick
    var trickCount: Int = 0
    var seatsKnownEmptyForSuit: [Suit : Set<Seat>] = Suit.allCases.reduce(into: [Suit : Set<Seat>]()) { $0[$1] = Set<Seat>() }
    var roundScore: [PartnerGroup : Int] = PartnerGroup.allCases.reduce(into: [:]) { $0[$1] = 0 }
    var winningTeam: PartnerGroup?
    var next: Seat?
    
    init(starting: Seat) {
        self.starting = starting
        self.currentTrick = Trick(starting: starting)
    }
    
    /// Stages with a playing round
    enum RoundStage {
        case starting, bidding(Bidding.BiddingStage), playing, ending
    }
}

extension Round {
    //MARK:- Update model methods
    
    mutating func startPlayingRound() {
        stage = .bidding(.first)
    }
    
    /// Make a deal of 4 cards on certain stage updates
    mutating func dealCardsOnStageUpdate(_ newStage: RoundStage) {
        guard newStage != stage else { return }
        switch newStage {
        case .bidding(.second) :
                hands.add4CardsToHands()
        default:
            return
        }
    }
    
    /// Select a card to be trump if bid is highest
    mutating func selectATrump(seat: Seat, trumpCard: Card) {
        unSelectATrump()
        hands.removeCardFromSeat(trumpCard, seat: seat)
        trump.bidder = seat
        trump.card = trumpCard
    }
    
    /// Return a previously selected trump to the player hand  (if not the top Bid)
    mutating func unSelectATrump() {
        if let currentTrump = trump.card, let currentBidder = trump.bidder {
            hands.hands[currentBidder]!.append(currentTrump)
            trump.bidder = nil
            trump.card = nil
        }
    }
    
    mutating func bid(seat: Seat, bid: Bid) {
        guard bid.points > (bidding.bid?.points ?? 0) else { return }
        bidding.bid = bid
        bidding.bidder = seat
        trump.bidder = seat
        trump.card = bid.card
        next = seat.nextSeat()
    }
    
    mutating func pass(seat: Seat) {
        // Re-instate trump card if erased by the user
        if let currentTrump = bidding.bid?.card, trump.card == nil {
            selectATrump(seat: seat, trumpCard: currentTrump)
        }
        
        bidding.passCount += 1
        next = seat.nextSeat()
    }
    
    /// Check round stage and advance if required
    mutating func advanceRoundStage() {
        assert(bidding.advanceStage, "Round not set to advance")
        // Set next to the top bidding seat in the just completed phase
        if bidding.stage == .first {
            bidding.passCount = 0
            bidding.stage = .second
            stage = .bidding(.second)
            next = bidding.bidder!
        }
        else {
            trump.card = bidding.bid!.card
            trump.bidder = bidding.bidder!
            stage = .playing
            next = starting
        }
    }
    
    mutating func startTrick() {
        assert(currentTrick.isComplete, "Current trick not complete")
        trickCount += 1
        let starting = currentTrick.seatToPlay
        currentTrick = Trick(starting: starting)
        next = starting
    }
    
    /// Play a card in a trick during playing stage of game of 28s
    mutating func playInTrick(seat: Seat, card: Card) {
        // Check to see if its the previously shown trump card
        if card == trump.card {
            trump.beenPlayed = true
        }
        
        // Update hand and trick
        hands.removeCardFromSeat(card, seat: seat)
        currentTrick.updateTrickWith(seat: seat, card: card)
        
        // Check to see if trick / round over
        if currentTrick.isComplete {
            updateRoundScore()
        }
        // Set next to the next seat to play
        else {
            next = currentTrick.seatToPlay
        }
    }
    
    /// Player at seat calls for the trump card to be revealed
    mutating func seatCallsTrump(_ seat: Seat) {
        assert(!trump.isCalled, "Trump was already called")
        trump.isCalled = true
        seatsKnownEmptyForSuit[currentTrick.leadSuit!]!.insert(seat)
        hands.returnTrumpToHand(trump: trump.card!, bidder: trump.bidder!)
        hands.updateTrumpCardRank(trumpSuit: trump.suit!)
    }
    
    /// Update trick scores
   mutating func updateRoundScore() {
        assert(currentTrick.isComplete, "Error - Trick not complete")
        roundScore[currentTrick.winningSeat!.partnerGroup]! += currentTrick.pointsInTrick
    }
    
    /// Check to see if there is a winner for the round
    mutating func checkForRoundWinner() -> Bool {
        let bidder = bidding.bidder!.partnerGroup
        let bidderWon: Bool  = roundScore[bidder]! >= bidding.bid!.points
        let opposingWon: Bool = roundScore[bidder.opposingTeam]! > (_28s.pointsInDeck - bidding.bid!.points)
        
        if bidderWon || opposingWon {
            winningTeam = bidderWon ? bidder : bidder.opposingTeam
            stage = .ending
            return true
        }
        else {
            return false
        }
    }
    
    
    //MARK: - Get model state methods
    
    /// All tricks have been played in current round
    var allTricksPlayed: Bool { trickCount == 7 }
    
    /// Return hand of eligible cards and bool of whether seat can call the trump if they wish and updates known empty seats if the hand is unable to play a limiting suit
    mutating func getEligibleCards(for seat: Seat, seatJustCalled: Bool) -> [Card] {
        var eligible = hands[seat]
        guard !(stage == .bidding(.first) || stage == .bidding(.second)) else { return eligible }
        
        if seat == .south {
            print("useractive")
        }
    
        // Player is limited to either following the lead suit or trump if they just called
        if !currentTrick.isEmpty {
            let limitSuit = seatJustCalled ? trump.suit! : currentTrick.leadSuit!
            let followingCards = hands[seat].filter { $0.suit == limitSuit }
            
            if !followingCards.isEmpty {
                eligible = followingCards
            }
            else {
                // Other players will know that player doesn't have card of this suit
                seatsKnownEmptyForSuit[limitSuit]!.insert(seat)
            }
        }
        
        // Also for the bidder only can't play trump until called unless following lead suit
        if seat == trump.bidder && !trump.isCalled && currentTrick.leadSuit != trump.suit {
            let excludingTrumps = eligible.filter { $0.suit != trump.suit }
            if !excludingTrumps.isEmpty  {
                eligible = excludingTrumps
            }
        }
        
        return eligible
    }

    
    /// The lowest points a seat can bid for the current stage of the game
    func bidMinForSeat(_ seat: Seat) -> Int {
        (bidding.stage == .first && bidding.bidder == seat.partner) ? 20 : max(bidding.stage.minimumBid, (bidding.bid?.points ?? 0) + 1)
    }
    
    /// Returns whether a seat can call trump
    func canSeatCallTrump(_ seat: Seat) -> Bool {
        guard (!trump.isCalled) else { return false }
        let hand = hands[seat]
        let isEmptyOflLeadSuit = !currentTrick.isEmpty && hand.filter {
            $0.suit == currentTrick.leadSuit }.isEmpty
        
        // Can only call if empty of lead suit or if you're the bidder and its the last round
        if isEmptyOflLeadSuit || (seat == trump.bidder && trickCount == 7) {
            return true
        }
        else {
            return false
        }
    }
    
    /// Returns true if this seat knows the trump suit
    func trumpIsKnowntoPlayer(_ seat: Seat) -> Bool {
        trump.isCalled || trump.bidder == seat
    }
}



extension Round.RoundStage: Equatable {
    /// Custom impletmentation of equatable - likely the same as the compiler synthesized version
    static func == (lhs: Round.RoundStage, rhs: Round.RoundStage) -> Bool {
        switch (lhs, rhs) {
        case (let .bidding(lhsBidStage), let .bidding(rhsBidStage)):
            return lhsBidStage == rhsBidStage
        case (.playing, .playing), (.starting, .starting):
            return true
        default:
            return false
        }
    }
    
    var textDescription: String {
        switch self {
        case .starting: return "Starting Bidding"
        case .bidding(.first): return "First distribution"
        case .bidding(.second): return "Second distribution"
        case .playing: return "Starting Playing"
        case .ending: return "Ending round"
        }
    }
}
