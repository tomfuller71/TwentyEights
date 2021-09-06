//
//  EndRoundView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 11/18/20.
//

import SwiftUI

struct EndRoundView: View {
    var userTeamWon: Bool
    var updatedTeamScore: Int
    var gamePoints: Int
    @Environment(\.cardValues) var cardValues
    
    
    var viewScore: Int {
        var score = updatedTeamScore
        if  userTeamWon {
            score -= gamePoints
            score += changeScorePoints
        }
        else {
            score += gamePoints
            score -= changeScorePoints
        }
        return score
    }
    
    @State var changeScorePoints: Int = 0
    
    @Binding var action: PlayerAction.ActionType?
    @Binding var showView: Bool
    
    var body: some View {
        
        VStack(spacing: nil) {
            Text(userTeamWon ? "Congratulations!" : "Unlucky!").fontWeight(.bold)
            Text(userTeamWon ? "You won \(gamePoints) points" : "You lost \(gamePoints) points")
            
            TeamScoreGaugeView(points: viewScore, roundEnded: true)
            
            Text("Tap to start new game")
                .padding([.top],5)
                .foregroundColor(.blue)
        }
        .frame(minWidth: cardValues.size.width * 3)
        .padding()
        .foregroundColor(Color.lead)
        .background(
            RoundedRectangle(cornerRadius: cardValues.size.width * 0.33)
                .fill(Color.offWhite)
                .shadow(color: .black, radius: 5, x: 3, y: 5)
        )
        .onTapGesture {
            showView = false
            action = .startNewRound
        }
        .onAppear {
            withAnimation(.default.delay(1)){
                changeScorePoints += gamePoints
            }
        }
    }
}

struct EndRoundView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundView()

                EndRoundView(userTeamWon: true, updatedTeamScore: 4, gamePoints: 2, action: .constant(nil), showView: .constant(true))
            }
            .previewFor28sWith(.iPhone8)
            
            ZStack {
                BackgroundView()
                
                EndRoundView(userTeamWon: true, updatedTeamScore: 4, gamePoints: 2, action: .constant(nil), showView: .constant(true))
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}
