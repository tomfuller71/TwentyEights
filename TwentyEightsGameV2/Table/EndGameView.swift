//
//  EndGameView.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/9/21.
//

import SwiftUI

struct EndGameView: View {
    let userTeamWins: Bool
    @Binding var action: PlayerAction.ActionType?
    @Environment(\.cardValues) var cardValues
    
    var body: some View {
        VStack {
            Text(userTeamWins ? " You're the winner!" : " Unlucky, you lost ..." )
                .fontWeight(.bold)
            
            Text("\(userTeamWins ? "A gift to the losers ..." : "...but enjoy your ear ornament!" )")
            Image("kunukka")
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(95))
                .frame(width: cardValues.size.width)
            
            
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
            action = .startNewGame
        }
    }
}




struct EndGameView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundView()
                EndGameView(userTeamWins: true,action: .constant(nil))
            }
            .previewFor28sWith(.iPhone8)
            
            ZStack {
                BackgroundView()
                EndGameView(userTeamWins: true,action: .constant(nil))
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}

