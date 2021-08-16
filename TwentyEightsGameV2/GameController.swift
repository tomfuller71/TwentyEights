//
//  GameModel.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 2/26/21.
//

import Foundation
import Combine

/// The top level controller of the game logic that holds an instance of the game model 
class GameController {
    //MARK: - Game properties
    var players: [Seat : Player]
    var starting: Seat
    
    var scores: [PartnerGroup : Int] = [
        .player : _28s.gameTeamStartingPoints,
        .opponent :  _28s.gameTeamStartingPoints
    ]
    
    var gameWinningTeam: PartnerGroup?
    var round: Round
    var roundCount: Int = 0
    var roundActions: [(Int, PlayerAction)] = []
    
    @Published var gameStage: GameStage = .playingRound(.starting)
    @Published var active: Seat
    @Published var seatJustCalledTrump: Seat?
    @Published var trickComplete: Bool = false
    @Published var roundStageAdvanced: Bool = false
    
    
    let defaults = UserDefaults.standard
    
    init(players: [ Seat : Player], starting: Seat = .south) {
        self.players = players
        self.starting = starting
        self.round = Round(starting: starting)
        self.active = starting
    }
}

extension GameController {
    
    //MARK: - User / AI intents
    /// Update model with player action and then take required game controller action
    func respondToPlayerAction(_ action: PlayerAction) {
        roundActions.append((roundCount, action)) // May use later for replay of rounds
        round.actions.append(action)
        updateModelWithAction(action)
        takeGameAction()
    }

     //MARK:- Game update methods
    /// Update model with player action
    private func updateModelWithAction(_ action: PlayerAction) {
        // Take the player action
        switch action.type {
    
        case .selectATrump(let trump):
            round.selectATrump(seat: action.seat, trumpCard: trump)
        
        case .unSelectATrump:
            round.unSelectATrump()
        
        case .makeBid, .pass:
            round.takeBiddingAction(action)
            
        case .playCardInTrick(_):
            if action.seat == seatJustCalledTrump {
                seatJustCalledTrump = nil
            }
            round.playInTrick(action: action)
            
        case .callForTrump:
            round.seatCallsTrump(action.seat)
            seatJustCalledTrump = action.seat
            
        case .startNewRound:
            newRound()
            
        case .startNewGame:
            newGame()
        }
        
        print(action.text)
    }
    
    /// Take a game action
    private func takeGameAction() {
        guard case .playingRound(let currentStage) = gameStage else { return }
        
        // Take next game action
        switch currentStage {
        case .bidding(_), .starting :
            checkRoundStageAdvance()
            
        case .playing:
            nextPlayingAction()
            
        default:
            return
        }
    }
    
    /// Checks to see whether a bidding stage has ended and advances the game and round stages accordingly
    private func checkRoundStageAdvance()  {
        if round.bidding.roundStageShouldAdvance() {
            roundStageAdvanced = true
            DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay) {
                self.round.advanceRoundStage()
                print("Advancing round stage to \(self.round.stage.textDescription)")
                self.roundStageAdvanced = false
                self.updateStage()
                self.setNextActive()
            }
        }
        else {
            setNextActive()
        }
    }
    
    /// Takes the next game controller action (as distinct from player actions)
    private func nextPlayingAction() {
        if round.currentTrick.isComplete {
            if round.checkForRoundWinner() {
                trickComplete = true
                print("Round over - \(round.winningTeam!.rawValue) won")
                DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay) {
                    self.trickComplete = false
                    self.updateGameScore()
                    self.updateStage()
                }
            }
            else {
                startNewTrick()
            }
        }
        else {
            setNextActive()
        }
    }
    
    /// Updates `gamestage` used by the playing table views for transistions
    private func updateStage() {
        print("Changed from \(gameStage.textDescription) to \(round.stage.textDescription)")
        
        if gameStage != .endingGame {
            gameStage = .playingRound(round.stage)
        }
    }
    
    /// Sets the `active` seat
    private func setNextActive() {
        // Either set to the seat that just called
        if let caller = seatJustCalledTrump {
            active = caller
        }
        // Or else set to the next player due to play in the round
        else if let next = round.next  {
            active = next
            round.next = nil
        }
        // Or if game is over set to next player starting
        else if gameStage == .playingRound(.ending) {
            active = starting
        }
    }
    
    

    
    /// Starts a new `currentTrick` in the `round`
    private func startNewTrick() {
        trickComplete = true
        DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay) {
            self.trickComplete = false
            if !self.round.allTricksPlayed {
                print("Game started new trick")
                self.round.startTrick()
                self.active = self.round.currentTrick.starting
            }
        }
    }
    
    /// Updates the game points for the teams at the end of a round
    private func updateGameScore() {
        guard let winner = round.winningTeam else { return }
        let points = _28s.gamePointsForBidOf(round.bidding.winningBid?.points ?? 0)
        
        scores[winner]! += points
        scores[winner.opposingTeam]! -= points
        
        // Check for endGame
        if scores[winner]! < 0 {
            gameWinningTeam = winner.opposingTeam
        }
        else if scores[winner.opposingTeam]! < 0 {
            gameWinningTeam = winner
        }
        
        if gameWinningTeam != nil {
            gameStage = .endingGame
        }
    }
    
    // TODO:- consolidate start round and newRound into one function
    /// Called to start a new round of the game
    private func newRound() {
        gameStage = .playingRound(.starting)
        
        if roundCount > 0 {
            starting = starting.nextSeat()
            round = Round(starting: starting)
        }
        
        roundCount += 1
        round.startRound()
        active = starting
    }

    
    /// Called to start a new game
    private func newGame() {
        scores = [.player :  _28s.gameTeamStartingPoints, .opponent :  _28s.gameTeamStartingPoints]
        newRound()
    }
    // MARK: - Get Game state methods
    
    /// Returns true if the seat has  an unrevealed trump
    func seatHasUnrevealedTrump(_ seat: Seat) -> Bool {
        round.trump.bidder == seat && !round.trump.isCalled
    }
    
    /// True if the game is in playing stage and the trick is complete
    var currentTrickComplete: Bool {
        if case .playing = round.stage, round.currentTrick.isComplete {
            return true
        }
        else {
            return false
        }
    }
}



