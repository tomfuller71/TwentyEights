//
//  CardBackView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 11/24/20.
//

import SwiftUI

struct CardBackView: View {
    
    var body: some View {
        
        GeometryReader { proxy in
            
            let width = proxy.size.width
            
            ZStack {
                RoundedRectangle(cornerRadius: width * _28s.card.cornerRadiusRatio)
                    .strokeBorder(_28s.card.strokeColor, lineWidth: width * _28s.card.strokeRatio)
                
                RoundedRectangle(cornerRadius: width * _28s.card.cornerRadiusRatio)
                    .inset(by: width * _28s.card.strokeRatio)
                    .fill(Color.white)
                    
                AngularGradient.cayenneSteel
                    .cornerRadius(width * _28s.card.cornerRadiusRatio * (1 - insetScale))
                    .scaleEffect(x: 1 - insetScale,
                                 y: 1 - (insetScale * _28s.card.aspect.width)
                    )
                
                Circle()
                    .fill(Color.white)
                    .scaleEffect(1 - (insetScale * 3))
                
                Circle()
                    .stroke(lineWidth: width * _28s.card.strokeRatio)
                    .overlay(
                        Image("smallJoker")
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(imageScale)
                    )
                    .scaleEffect(1 - (insetScale * 4))
                
            }
        }
        .aspectRatio(_28s.card.aspect, contentMode: .fit)
        .drawingGroup()
    }
    
    private var insetScale: CGFloat = 0.125
    private var imageScale: CGFloat { 1 - (3 * insetScale) }
}

struct CardBackView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 20) {
                Spacer()
                Spacer()
                CardBackView()
                    .frame(height: 250)
                Spacer()
                Text("Standard size").foregroundColor(.white)
                HStack(spacing: 30) {
                    CardBackView()
                    CardView(card: Card(face: .eight, suit: .heart))
                }
                .frame(height: _28s.cardSize_screenHeight_667.height)
                Spacer()
            }
        }
    }
}
