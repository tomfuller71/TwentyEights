//
//  TeamScoreView.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import SwiftUI

/// View that shows the current scores for a team
struct TeamScoreView: View {
    var team: Team
    var scores: UserView.ScoresViewModel.TeamScore
    
    @Environment(\.cardValues) var cardValues
    var hideGauge: Bool { scores.gamePoints == 0 }

    
    var body: some View {
        //Player team scores
        
        let align: HorizontalAlignment =  team == .player ? .leading : .trailing
        
        
        VStack(alignment: align, spacing: 5) {
            Text(team.rawValue)
                .bold()
            
           TeamScoreGaugeView(points: scores.gamePoints, roundEnded: false)
                .opacity(hideGauge ? 0 : 1)
                .padding([.leading,.trailing], 2)

            
           Text("Points: \(scores.roundPoints)")
                .opacity(scores.isPlaying ? 1 : 0)
                // Hack to stop having conditional view that resizes parent
                .offset(y: hideGauge ? -cardValues.fontSize * 1.45 : 0)
        }
        .font(.copperPlate, size: cardValues.fontSize)
    }
    
}

struct TeamScoreView_Previews: PreviewProvider {
    static var previews: some View {
        let score1 = UserView.ScoresViewModel.TeamScore(
            isPlaying: true,
            gamePoints: 0,
            roundPoints: 17
        )
        
        let score2 = UserView.ScoresViewModel.TeamScore(
            isPlaying: true,
            gamePoints: -4,
            roundPoints: 1
        )
        
    
        ZStack(alignment: .center) {
            BackgroundView()
            HStack {
                TeamScoreView(team: .player, scores: score1)
                Spacer()
                Spacer()
                TeamScoreView(team: .opponent, scores: score2)
            }
            .foregroundColor(.offWhite)
            .padding([.leading,.trailing], 7)
        }
        .previewFor28sWith(.iPhone8)
    }
}
