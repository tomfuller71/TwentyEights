//
//  Round.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import Foundation

/// Data model for one round of 28s
struct Round {
    //MARK: Round properties
    let starting: Seat
    var hands: RoundCards = RoundCards()
    
    var stage: RoundStage = .starting {
        willSet { dealCardsOnStageUpdate(newValue) }
    }
    
    var actions: [PlayerAction] = []
    var bidding: Bidding = Bidding()
    var trump = Trump()
    var currentTrick: Trick
    var trickCount: Int = 0
    
    var seatsKnownEmptyForSuit: [Suit : Set<Seat>] = Suit.allCases
        .reduce(into: [Suit : Set<Seat>]()) { $0[$1] = Set<Seat>() }
    
    var suitsKnownCantBeTrump: Set<Suit> = []
    
    var roundScore: [Team : Int] = Team.allCases
        .reduce(into: [:]) { $0[$1] = 0 }
    
    var winningTeam: Team?
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
    
    /// Called to start playing a new round
    mutating func startRound() {
        stage = .bidding(.first)
        hands.add4CardsToHands()
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
            hands.returnTrumpToHand(trump: currentTrump, bidder: currentBidder)
            trump.bidder = nil
            trump.card = nil
        }
    }
    
    mutating func takeBiddingAction(_ action: PlayerAction) {
        bidding.updateWith(action)
        
        switch action.type {
        case .makeBid(let bid):
            selectATrump(seat: bid.bidder, trumpCard: bid.card)
            
        case .pass:
            // Re-instate trump card if erased by the user
            if let currentTrump = bidding.winningBid?.card, trump.card == nil {
                selectATrump(seat: bidding.winningBid!.bidder, trumpCard: currentTrump)
            }
            
        default:
            print("Error - invalid action type received")
        }
        
        next = action.seat.nextSeat()
    }
    
    /// Check round stage and advance if required
    mutating func advanceRoundStage() {
        // Set next to the top bidding seat in the just completed phase
        if bidding.stage == .first {
            bidding.clearActionsAndPasses()
            bidding.stage = .second
            stage = .bidding(.second)
            next = bidding.winningBid!.bidder
        }
        else {
            trump.card = bidding.winningBid!.card
            trump.bidder = bidding.winningBid!.bidder
            stage = .playing
            next = starting
        }
    }
    
    mutating func startTrick() {
        assert(currentTrick.isComplete, "Current trick not complete")
        trickCount += 1
        print("Trick # \(trickCount)")
        let starting = currentTrick.seatToPlay
        currentTrick = Trick(starting: starting)
        next = starting
    }
    
    /// Play a card in a trick during playing stage of game of 28s
    mutating func playInTrick(action: PlayerAction) {
        guard case .playCardInTrick(let card) = action.type else {
            print("Error - Invalid action type received")
            return
        }
        
        hands.removeCardFromSeat(card, seat: action.seat)
        
        let isTrump = cardIsATrump(card: card)
        
        currentTrick.updateTrickWithAction(
            action: action,
            isTrump: isTrump
        )
        
        updateRoundKnowledge(seat: action.seat, card: card)
    }
    
    /// Update round state based on card just played
    mutating func updateRoundKnowledge(seat: Seat, card: Card) {
        // Check to see if its the previously shown trump card
        if card == trump.card {
            trump.beenPlayed = true
        }
        
        if currentTrick.seatActions.count == 1 {
            // If bidder leads a suit prior to trump being called then that suit can't be Trump
            if !trump.isCalled && seat == trump.bidder {
                suitsKnownCantBeTrump.insert(card.suit)
            }
        }
        // Or if someone doesnt follow lead card then must be empty of lead
        else if card.suit != currentTrick.leadSuit {
            seatsKnownEmptyForSuit[currentTrick.leadSuit!]!.insert(seat)
        }
        
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
        hands.returnTrumpToHand(trump: trump.card!, bidder: trump.bidder!)
        hands.updateTrumpCardRank(trumpSuit: trump.suit!)
    }
    
    /// Update trick scores
   mutating func updateRoundScore() {
        assert(currentTrick.isComplete, "Error - Trick not complete")
        roundScore[currentTrick.winningSeat!.team]! += currentTrick.pointsInTrick
    }
    
    /// Check to see if there is a winner for the round
    mutating func checkForRoundWinner() -> Bool {
        let bidder = bidding.winningBid!.bidder.team
        let bidderWon: Bool  = roundScore[bidder]! >= bidding.winningBid!.points
        let opposingWon: Bool = roundScore[bidder.opposingTeam]! > (_28s.pointsInDeck - bidding.winningBid!.points)
        
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
    var lastTrickOfRound: Bool { trickCount == 7 }
    
    /// Return hand of eligible cards and bool of whether seat can call the trump if they wish and updates known empty seats if the hand is unable to play a limiting suit
    func getEligibleCards(for seat: Seat, seatJustCalled: Bool) -> [Card] {
        if seatJustCalled {
            print("Should filter for trumps only")
        }
        
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
    
    /// Returns whether a seat can call trump
    func canSeatCallTrump(_ seat: Seat) -> Bool {
        guard (!trump.isCalled) else { return false }
        
        let hand = hands[seat]
        
        let isEmptyOflLeadSuit = !currentTrick.isEmpty && hand.filter {
            $0.suit == currentTrick.leadSuit }
            .isEmpty
        
        // Can only call if empty of lead suit or if you're the bidder and its the last trick of round
        if isEmptyOflLeadSuit || (seat == trump.bidder && lastTrickOfRound) {
            return true
        }
        else {
            return false
        }
    }
    
    func getSetofSeats(type: Seat.SetType) -> Set<Seat> {
        switch type {
        case .all:
            return Set(Seat.allCases)
        case .yetToPlay:
            return currentTrick.seatsYetToPlay
        case .following:
            return currentTrick.followingSeats
        }
    }
    
    /// Returns true if the card is played as a trump
    func cardIsATrump(card: Card) -> Bool {
        return trump.isCalled && card.suit == trump.suit
    }
    
    /// Returns true if this seat knows the trump suit
    func trumpIsKnowntoPlayer(_ seat: Seat) -> Bool {
        trump.isCalled || trump.bidder == seat
    }
    
    /// Return the points won or lost for the current round
    func getGamePoints() -> Int {
        guard let winner = winningTeam else { return 0 }
        var points = _28s.gamePointsForBidOf(bidding.winningBid!.points)
        
        // Add one if the bidding team lost
        if trump.bidder!.team != winner {
            points += 1
        }
        return points
    }
}



extension Round.RoundStage: Equatable {
    /// Custom impletmentation of equatable - likely the same as the compiler synthesized version
    static func == (lhs: Round.RoundStage, rhs: Round.RoundStage) -> Bool {
        switch (lhs, rhs) {
        case (let .bidding(lhsBidStage), let .bidding(rhsBidStage)):
            return lhsBidStage == rhsBidStage
        case (.playing, .playing), (.starting, .starting), (.ending, .ending):
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
