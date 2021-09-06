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
        .padding([.leading,.trailing], 5)
    }
}



struct ScoresView_Previews: PreviewProvider {
    static var previews: some View {
        
        let model: UserView.ScoresViewModel = {
            var viewModel = UserView.ScoresViewModel()
            viewModel.bid.bidPoints = 14
            viewModel.bid.trumpSuit = .heart
            viewModel.bid.bidIndicator = .left
            viewModel.bid.trumpCalled = true
            viewModel.teams[Team.player] = UserView.ScoresViewModel.TeamScore(
                isPlaying: true, gamePoints: 0, roundPoints: 8)
            viewModel.teams[Team.opponent] = UserView.ScoresViewModel.TeamScore(
                isPlaying: true, gamePoints: -3, roundPoints: 1)
            
            return viewModel
        }()
        
        
        Group {
            ZStack {
                BackgroundView()
                
                ScoresView(scores: model)
                    .font(.copperPlate)
                   // .frame(maxHeight: 129.5 * 0.4)
            }
            .previewFor28sWith(.iPadPro_12_9)
            
            
            ZStack {
                BackgroundView()
                
                ScoresView(scores: model)
                    .font(.copperPlate)
                    //.frame(maxHeight: 129.5 * 0.4)
            }
            .previewFor28sWith(.iPhone8)
        }
    }
}
