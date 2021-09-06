//
//  CardBackView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 11/24/20.
//

import SwiftUI

struct CardBackView: View {
    @Environment(\.cardValues) var cardValues
    var width: CGFloat { cardValues.size.width }
    var height: CGFloat { cardValues.size.height }
    
    var body: some View {
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
                    Text("28")
                        .font(.custom("Copperplate", fixedSize: width * imageScale))
                )
                .scaleEffect(1 - (insetScale * 4))
        }
        .frame(width: cardValues.size.width, height: cardValues.size.height)
        .drawingGroup()
    }
    
    private var insetScale: CGFloat = 0.125
    private var imageScale: CGFloat { 1 - (3 * insetScale) }
}

struct CardBackView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundView()
                VStack(spacing: 20) {
                    Spacer()
                    Text("Standard size").foregroundColor(.white)
                    CardBackView()
                    Spacer()
                }
            }
            .previewFor28sWith(.iPhone8)
            ZStack {
                BackgroundView()
                VStack(spacing: 20) {
                    Spacer()
                    Text("Standard size").foregroundColor(.white)
                    CardBackView()
                    Spacer()
                }
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}
