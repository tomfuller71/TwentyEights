//
//  StatusBannerView.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/8/21.
//

import SwiftUI

/// View at top of TableView that contains scores and final bid information
struct ScoresView: View {
    var scores: UserView.ScoresViewModel
    
    var body: some View {
        HStack(alignment: .top) {
            TeamScoreView(team: .player, scores: scores.teams[.player]!)
            
            Spacer()
            
            FinalBidView(bid: scores.bid)
            
            Spacer()
            
            TeamScoreView(team:.opponent, scores: scores.teams[.opponent]!)
        }
        .foregroundColor(.offWhite)
        .padding([.leading,.trailing], 7)
    }
}



struct ScoresView_Previews: PreviewProvider {
    static var previews: some View {
        
        let model: UserView.ScoresViewModel = {
            let userView = UserView(game: GameController(players: _28s.players))
            userView.game.round.trump.card = Card(face: .ace, suit: .club)
            userView.game.gameStage = .playingRound(.playing)
            userView.game.round.bidding.winningBid = Bid(
                points: 14,
                card: Card(face: .ace, suit: .club),
                bidder: .north
                //stage: .first
            )
 
            userView.game.round.trump.bidder = .north
            userView.updateScores()
            
            return userView.scores
        }()
        
        ZStack {
            BackgroundView()
            
            ScoresView(scores: model)
                .font(.copperPlate)
        }
    }
}
