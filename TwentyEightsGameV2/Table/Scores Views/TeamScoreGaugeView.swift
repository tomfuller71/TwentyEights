//
//  TeamScoreGaugeView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/19/21.
//

import SwiftUI

struct TeamScoreGaugeView: View {
    //Init with Joker points for team
    var points: CGFloat
    var fillColor: Color {
        switch self.points {
        case 0 ... 2:   return Color.cayenne
        case 3 ..< 6:   return Color.lemon
        default:        return Color.moss
        }
    }
    
    var body: some View {
        ZStack {
            Capsule()
                .strokeBorder(Color.offWhite, lineWidth: 1.5)
            Capsule()
                .fill(fillColor)
                .scaleEffect(x: (points / 12) * 0.87, y: 0.5, anchor: .leading)
                .offset(x: 4)
        }
        .frame(width: 60, height: 15, alignment: .center)
    }
}

struct TeamScoreGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            TeamScoreGaugeView(points: 4)
        }
    }
}
