//
//  UserView.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import SwiftUI
import Combine

class UserView: ObservableObject {
    //MARK:- Class properties
    private(set) var game: GameController
    
    private(set) var userSeat: Seat
    
    // Player action taken
    var playerAction: PlayerAction.ActionType? {
        didSet {
            playerActionReponse()
        }
    }
    
    // Game properties (linked to model via combine publishers)
    private(set) var activeSeat : Seat {
        didSet {
            respondToActiveSeatChange(oldValue)
        }
    }
    
    @Published private(set) var gameStage: GameStage {
        willSet {
            gameActionResponse()
            
            // Needed to remove trump placeholder on start playing
            if newValue == .playingRound(.playing) {
                withAnimation {
                    userCards = updateUserCardsModel()
                }
            }
        }
    }
    
    @Published private(set) var currentTrickComplete: Bool {
        willSet {
            if newValue == true {
                gameActionResponse()
            }
        }
    }
    
    @Published private(set) var roundStageAdvanced: Bool {
        willSet {
            if newValue == true {
                stageChangeResponse()
            }
        }
    }
    
    @Published private(set) var seatJustCalledTrump: Seat? {
        willSet {
            if newValue != nil {
                userCards = updateUserCardsModel()
                updateScores()
            }
        }
    }
    
    // Sub view models
    @Published private(set) var userCards = UserCardsModel()
    @Published private(set) var scores = ScoresViewModel()
    @Published private(set) var seats = SeatSelectionViewModel()
    @Published private(set) var alerts = AlertViewModel()
    @Published private(set) var picker: BidPickerModel

    // Holds cancel tokens for combine publishers in the game data model
    private var gameStageCancellable: AnyCancellable?
    private var activeCancellable: AnyCancellable?
    private var trickCompleteCancellable: AnyCancellable?
    private var roundStageAdvancedCancellable: AnyCancellable?
    private var seatJustCalledCancellable: AnyCancellable?
    
    init(userSeat: Seat = .south, game: GameController) {
        self.game = game
        self.userSeat = userSeat
        self.activeSeat = game.active
        self.gameStage = game.gameStage
        self.picker = BidPickerModel(seat: userSeat)
        self.currentTrickComplete = game.trickComplete
        self.roundStageAdvanced = game.roundStageAdvanced
        self.gameStageCancellable = self.game.$gameStage.assign(to: \.gameStage, on: self)
        self.activeCancellable = self.game.$active.assign(to: \.activeSeat, on: self)
        
        self.trickCompleteCancellable = self.game.$trickComplete
           .assign(to: \.currentTrickComplete, on: self)
        self.roundStageAdvancedCancellable = self.game.$roundStageAdvanced
            .assign(to: \.roundStageAdvanced, on: self)
        self.seatJustCalledCancellable = self.game.$seatJustCalledTrump
            .assign(to: \.seatJustCalledTrump, on: self)
    }
}


//MARK: - Computed properties
extension UserView {
    /// True if the user is the seat that can take a game PlayerAction
    var userIsActive: Bool { userSeat == activeSeat }
    
    /// True if the user has the trump card that has yet to be called
    var userHasTrump: Bool { game.seatHasUnrevealedTrump(userSeat) }
    
    /// True if the users team  has won the game
    var userTeamWon: Bool { game.gameWinningTeam == userSeat.team }
    
    /// The  card that was selected by the top bid as the hidden trump in a round
    var roundTrump: Card? { game.round.trump.card }
    
    /// True if the game is currently in either the first or second stage of bidding
    var isBidding: Bool {
        if case .bidding(_) = game.round.stage { return true } else { return false }
    }
    
    /// True if the games is currently is the "playing"  phase of a round
    private var isPlaying: Bool {
        if case .playing = game.round.stage { return true } else { return false }
    }
    
    /// True is the user can pass in a bidding round
    private var canPass: Bool { game.round.bidding.winningBid != nil }
    
    private var userNotPlayed: Bool { game.round.currentTrick.seatsYetToPlay.contains(userSeat) }
    
    private var trickComplete: Bool { game.round.currentTrick.isComplete }
    
    private var userIsLastBidder: Bool {
        game.round.actions.filter { action in
            switch action.type {
            case .makeBid(_):
                return true
            default:
                return false
            }
        }
        .last?.seat == userSeat
    }
}

// MARK: - Update methods
extension UserView {
    /// Responds to player action being set in table and calls the appropriate game round function
    private func playerActionReponse() {
        guard let action = playerAction else { return }
        
        game.respondToPlayerAction(PlayerAction(seat: userSeat, type: action))
        playerAction = nil
        userCards = updateUserCardsModel()
        alerts = updateAlert()
        updateScores()
        
        if isBidding {
            picker = updateBidPicker()
        }
    }
    
    /// Respond to game controller action
    private func gameActionResponse() {
        withAnimation {
            updateSeatActionView()
            updateScores()
            alerts = updateAlert()
        }
    }
    
    
    private func stageChangeResponse() {
        withAnimation {
            updateSeatActionView()
            updateScores()
            alerts = updateAlert()
            userCards = updateUserCardsModel()
            //picker = updateBidPicker()
        }
    }
    
    /// Updates the view model based on response to active seat changing
    private func respondToActiveSeatChange(_ old: Seat) {
        
        withAnimation {
            alerts = updateAlert()
        }
        
        // Updates seat view unless moving to user playing at the end of a trick
        if !(trickComplete && game.round.next == userSeat) {
            withAnimation {
                updateSeatActionView()
            }
        }
        
        if userIsActive {
            userCards = updateUserCardsModel()
            
            if isBidding {
                if game.round.trump.bidder != nil {
                    updateScores()
                }
                
                picker = updateBidPicker()
            }
        }
    }
}

// MARK: - UserCards
extension UserView {
    struct UserCardsModel {
        var hand: [Card] = []
        var eligibleCards: [Card] = []
        var isActive: Bool = false
        var trump: Card? = nil
        var isBidding: Bool = true
        
        func iseligibleToPlay(_ selectedCard: Card) -> Bool {
            eligibleCards.contains(selectedCard)
        }
    }
    
    private func updateUserCardsModel() -> UserCardsModel {
        let cards = game.round.hands[userSeat]
            .sorted { ($0.suit.rawValue, $0.currentRank) > ($1.suit.rawValue, $1.currentRank) }
        
        let trump: Card? =  userHasTrump ? game.round.trump.card! : nil
        var eligible: [Card] {
            if !userIsActive || trickComplete {
                return []
            }
            else {
                if !isBidding && userNotPlayed {
                    return game.round.getEligibleCards(
                        for: userSeat,
                        seatJustCalled: (game.seatJustCalledTrump != nil))
                }
                else if isBidding && !userHasTrump {
                    return cards
                }
                else {
                    return []
                }
            }
        }
        
        return UserCardsModel(
            hand: cards,
            eligibleCards: eligible,
            isActive: userIsActive,
            trump: trump,
            isBidding: isBidding
        )
    }
}

//MARK: - Scores
extension UserView {
    struct ScoresViewModel {
        /// Dictionary that stores  the current TeamScoreView properties for each team
        var teams: [Team : TeamScore] = Team.allCases
            .reduce(into: [:]) {
                $0[$1] = TeamScore()
            }
        
        /// Stores  the current properties of the FinalBidView
        var bid = BidStatus()
        
        /// The properties of a TeamScoreView
        struct TeamScore {
            var isPlaying: Bool = false
            var gamePoints: Int = _28s.gameTeamStartingPoints
            var roundPoints: Int = 0
        }
        
        /// The properties of the FinalBidView
        struct BidStatus: Hashable {
            var bidPoints: Int = 0
            var trumpCalled: Bool = false
            var trumpSuit: Suit?
            var bidIndicator: Direction?
        }
        
        /// Enumeration of the direction if which the BIdStatus indicator arrow points
        enum Direction: String, Equatable {
            case left, right
        }
    }
    
    /// Updates the user views score properties based on the current game state
    func updateScores() {
        for team in scores.teams.keys {
            scores.teams[team] =  ScoresViewModel.TeamScore(
                isPlaying: isPlaying,
                gamePoints: game.scores[team]!,
                roundPoints: game.round.roundScore[team]!
            )
        }
        
        var bidIndicator: ScoresViewModel.Direction? {
            if game.round.trump.bidder?.team == .player {
                return .left
            }
            else if game.round.trump.bidder?.team == .opponent {
                return .right
            }
            else {
                return nil
            }
        }
        
        scores.bid = ScoresViewModel.BidStatus(
            bidPoints: game.round.bidding.winningBid?.points ?? 0,
            trumpCalled: game.round.trump.isCalled,
            trumpSuit: game.round.trump.card?.suit,
            bidIndicator: bidIndicator
        )
    }
}

//MARK: - Seats
extension UserView {
    /// Properties of the SeatView
    struct SeatSelectionViewModel {
        var selections: [PlayerAction] = []
        var highlightSeat: Seat?
        var indicatorAngle: Angle = .degrees(0)
    }
    
    /// Updates the current seat Action view model
    private func updateSeatActionView() {
        if isBidding {
            seats.selections = game.round.bidding.actions
            
            // Starting angle
            seats.indicatorAngle =
                Angle(
                    degrees: game.round.bidding.winningBid?.bidder.angle ?? game.round.starting.angle
                )
        }
        else {
            
            seats.selections = game.round.currentTrick.seatActions
            
            seats.highlightSeat = game.round.currentTrick.winningSeat
            
            // Starting angle
            seats.indicatorAngle =
                Angle(degrees: game.round.currentTrick.starting.angle)
            
        }
        // Add 90 degrees to angle per selection
        seats.indicatorAngle += Angle(degrees: Double(min(seats.selections.count, 3)) * 90 )
    }
    
    
    /// Updates the seats selection view model
    private func updateSeatsViewModel() -> SeatSelectionViewModel {
        var angleCount = 0
        var actions = [PlayerAction]()
        var highlight: Seat?
        
        if isBidding {
            actions = game.round.bidding.actions
            angleCount = min(actions.count, 3)
        }
        
        if isPlaying || game.round.stage == .ending {
            let trickCards = game.round.currentTrick.seatActions
            actions = trickCards
            angleCount = min(trickCards.count, 3)
            highlight = game.round.currentTrick.winningSeat
        }
        
        
        var startingAngle: Angle {
            if isPlaying {
                return Angle(degrees: game.round.currentTrick.starting.angle)
            }
            else {
                return Angle(
                    degrees: game.round.bidding.winningBid?.bidder.angle ?? game.round.starting.angle)
            }
        }
        
        let angle = startingAngle + Angle(degrees: Double(angleCount) * 90)
        
        return SeatSelectionViewModel(
            selections: actions,
            highlightSeat: highlight,
            indicatorAngle: angle
        )
    }
}
    

//MARK: - Picker
extension UserView {
    /// Model of the properties in a BidPickerView
    struct BidPickerModel {
        var seat: Seat
        var pickerValues: [Int] = []
        var stage = Bidding.BiddingStage.first
        var minBid: Int = Bidding.BiddingStage.first.minimumBid
        var canBid: Bool = false
        var canPass: Bool = false
        var trump: Card?
    }
    
    /// Returns updated picker sub-view model
    private func updateBidPicker() -> BidPickerModel {
        guard (userIsActive && isBidding) else { return BidPickerModel(seat: userSeat) }
        
        var maxBid: Int {
            var max = game.round.bidding.stage.maximumBid
            if (game.round.bidding.winningBid?.points ?? 0) >= max {
                max = Bidding.BiddingStage.second.maximumBid
            }
            return max
        }
        
        var minBid: Int { game.round.bidding.bidMinForSeat(userSeat) }
        
        return BidPickerModel(
            seat: userSeat,
            pickerValues: Array(minBid ... maxBid),
            stage: game.round.bidding.stage,
            minBid: minBid,
            canBid: userHasTrump,
            canPass: canPass,
            trump: userHasTrump ? game.round.trump.card! : nil
        )
    }
}

//MARK: - Alerts
extension UserView {
    /// AlertView properties
    struct AlertViewModel {
        var statusText: String = ""
        var userCanCallTrump: Bool = false
        var hideView: Bool = true
    }
    
    /// True if the user has can call for the trump card to be shown
    private var canCall: Bool {
        (isPlaying && userIsActive && !trickComplete) ? game.round.canSeatCallTrump(userSeat) : false
    }
    
    /// Returns an updated user alert sub-view model
    private func updateAlert() -> AlertViewModel {
        var status: String {
            var status: String = ""
            
            if game.round.currentTrick.isComplete {
                status = "\(game.round.currentTrick.winningSeat!) won the trick"
            }
            else if userIsActive {
                if isBidding {
                    status = userHasTrump  ? "Make a Bid" : "Select a Trump"
                    if canPass {
                        status = status + " or Pass"
                    }
                }
                else {
                    status = "Play a Card"
                }
            }
            else {
                if isBidding {
                    status = "\(activeSeat.name.capitalized) to bid"
                }
                else {
                    status = "\(activeSeat.name.capitalized) to play"
                }
            }
            
            return status
        }
        
        return AlertViewModel(
            statusText: !canCall ? status : "Call for trump",
            userCanCallTrump: canCall,
            hideView: game.gameWinningTeam != nil || (status == "")
        )
    }
}
