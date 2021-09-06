//
//  TeamScoreGaugeView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct TeamScoreGaugeView: View {
    //Init with Joker points for team
    var points: Int
    var roundEnded: Bool
    @Environment(\.cardValues) var cardValues
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<6) { i in
                Image(systemName: "circle.fill")
                    .foregroundColor(getColor(index: i))
                    .font(.custom("system", size: cardValues.fontSize * 0.63))
                    //.frame(maxWidth: 20)
            }
        }
        .padding([.top,.bottom], 4)
        .background(
            Capsule()
                .strokeBorder(
                    roundEnded ? Color.black : Color.offWhite, lineWidth: 1.5
                )
                .padding([.leading,.trailing], -3)
        )
        //.padding()
        //.frame(maxWidth: 100)
    }
    
    private func getColor(index: Int) -> Color {
        var color = Color.clear
        
        if points > 0  && index < points{
            color = .cayenne
        }
        else if points < 0 && index < points * -1 {
                color = .black
        }
        return color
    }
}

struct TeamScoreGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            TeamScoreGaugeView(points: -6, roundEnded: false)
        }
        .previewFor28sWith(.iPhone11_Pro)
    }
}
