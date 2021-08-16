//
//  EndRoundView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 11/18/20.
//

import SwiftUI

struct EndRoundView: View {
    let userTeamWon: Bool
    let gamePoints: Int
    @Binding var action: PlayerAction.ActionType?
    @Binding var showView: Bool
    
    var body: some View {
    
        VStack(spacing: nil) {
            Text(userTeamWon ? "Congratulations!" : "Unlucky!").fontWeight(.bold)
            Text(userTeamWon ? "You won" : "You lost")
                
            HStack(spacing: 5) {
                ForEach(0 ..< gamePoints, id: \.self) { _ in
                    Image("smallJoker")
                        .frame(width: 30, height: 30)
                        .scaleEffect(30/309)
                }
            }
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
            showView = false
            action = .startNewRound
        }
        // TODO: - maybe put back if a multiplayer as can't have a multiple people starting or waiting
        /* .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay * 2 ) {
                showView = false
                action = .startNewRound
            }
        } */
    }
}

struct EndRoundView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()

            EndRoundView(userTeamWon: true, gamePoints: 2, action: .constant(nil), showView: .constant(true))
        }
        .font(.copperPlate)
    }
}
