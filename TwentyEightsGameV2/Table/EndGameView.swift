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
    
    var body: some View {
        VStack {
            Text(userTeamWins ? " You're the winner!" : " Unlucky, you lost ..." )
                .fontWeight(.bold)
            
            Text("\(userTeamWins ? "A gift to the losers ..." : "...but enjoy your ear ornament!" )")
            Image("kunukka")
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(95))
                .frame(width: 100)
            
            
            Text("Tap to start new game")
                .padding([.top],5)
                .foregroundColor(.blue)
        }
        .frame(minWidth: 290)
        .padding()
        .foregroundColor(Color.lead)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.offWhite)
                .shadow(color: .black, radius: 5, x: 3, y: 5)
        )
        .onTapGesture {
            action = .startNewGame
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay * 2 ) {
                action = .startNewGame
            }
        }
    }
}




struct EndGameView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            EndGameView(userTeamWins: true,action: .constant(nil))
                .font(.copperPlate)
        }
    }
}

