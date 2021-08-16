//
//  TeamScoreView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

/// View that shows the current scores for a team
struct TeamScoreView: View {
    var team: PartnerGroup
    var scores: UserView.ScoresViewModel.TeamScore
    
    var body: some View {
        //Player team scores
        VStack(spacing: 2) {
            Text(team.rawValue)
                .bold()
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(team == .player ? Color.moss : Color.cayenne)
                        .frame(width: 85)
                )
            
            HStack(spacing: 0) {
                Image("smallJoker")
                    .frame(width: 20, height: 20)
                    .scaleEffect(20/309)
                    .padding([.leading, .trailing], 2)
                
                TeamScoreGaugeView(points: CGFloat(scores.gamePoints))
            }
            
            Text("Points: \(scores.roundPoints)")
                .opacity(scores.isPlaying ? 1 : 0)
                .padding([.leading], 5)
        }
        .padding([.top], 2)
    }
}

struct TeamScoreView_Previews: PreviewProvider {
    static var previews: some View {
        let score1 = UserView.ScoresViewModel.TeamScore(
            isPlaying: true,
            gamePoints: 4,
            roundPoints: 17
        )
        
        let score2 = UserView.ScoresViewModel.TeamScore(
            isPlaying: false,
            gamePoints: 4,
            roundPoints: 0
        )
    
        ZStack {
            BackgroundView()
            HStack {
                TeamScoreView(team: .player, scores: score1)
                Spacer()
                TeamScoreView(team: .opponent, scores: score2)
            }
            .foregroundColor(.offWhite)
            .padding([.leading,.trailing], 7)
        }
        .environment(\.font, .copperPlate)
    }
}
