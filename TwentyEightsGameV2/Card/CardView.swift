//
//  Card.swift
//  TwentyEights
//
//  Created by Tom Fuller on 10/7/20.
//

import SwiftUI



/// Playing card view
struct CardView: View {
    let card: Card
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack {
                Color.white.cornerRadius(width * _28s.card.cornerRadiusRatio)
                RoundedRectangle(cornerRadius: width * _28s.card.cornerRadiusRatio)
                    .strokeBorder(_28s.card.strokeColor, lineWidth: width * _28s.card.strokeRatio)
                
                let fontScale = width * sizeRatio
                ZStack(alignment: .topLeading) {
                    Color.clear
                    CardCornerView(card: card, fontScale: fontScale)
                        .padding([.leading], cornerPaddingRatio * width)
                }
                
                ZStack(alignment: .bottomTrailing) {
                    Color.clear
                    CardCornerView(card: card, fontScale: fontScale)
                        .rotationEffect(.degrees(180.0), anchor: .center)
                        .padding([.trailing], cornerPaddingRatio * width)
                }
                Group {
                    if isCourtOrAce {
                        CourtOrAceCenterView(card: card, fontSize: width * courtFontRatio)
                    }
                    else {
                        CardInsertView(
                            card: card,
                            width: width * cardCenterWidthRatio,
                            height: proxy.size.height * cardCenterHeightRatio
                        )
                    }
                }
            }
        }
        .aspectRatio(_28s.card.aspect, contentMode: .fit)
        .drawingGroup()
    }
    
    private let sizeRatio: CGFloat = 0.3
    private let cornerPaddingRatio: CGFloat = 0.03
    private var cardCenterWidthRatio: CGFloat { 1 - (2 * (sizeRatio + cornerPaddingRatio)) }
    private let cardCenterHeightRatio: CGFloat = 0.5
    private let courtFontRatio: CGFloat = 0.6
    private var isCourtOrAce: Bool { card.face == .ace || card.face.index > 9 }
}

extension CardView {
    /// The corner of a card
    struct CardCornerView: View {
        var card: Card
        var fontScale: CGFloat
        
        var body: some View {
            VStack {
                Text(card.face.rawValue)
                    .font(.system(size: fontScale)).tracking(compressTen)
                Text(card.suit.rawValue)
                    .font(.custom("Copperplate", size: fontScale))
                    .offset(x: 0, y: suitTextOffset)
            }
            .foregroundColor(card.suit.suitColor)
        }
        private var suitTextOffset: CGFloat { fontScale * -0.33 }
        private var compressTen: CGFloat { card.face == .ten ? (fontScale * -0.1 ) : 0 }
    }
    
    /// The inside of a CardView
    struct CardInsertView: View {
        var card: Card
        var flashes: [CardFlashPosition] { CardFlashes.getFlashes(for: card) }
        var width: CGFloat
        var height: CGFloat
        
        var body: some View {
            // Flashes is an array of CardFlashPositions from the Face enumeration
            ForEach(flashes, id: \.self) { flash in
                Text(card.suit.rawValue)
                    .rotationEffect(flash.inverted ? .degrees(180) : .zero )
                    .position(
                        x: width * flash.xOffset,
                        y: height * flash.yOffset
                    )
                    .foregroundColor(card.suit.suitColor)
                    .font(.custom("Copperplate", size: width * fontScale))
            }
           .frame(width: width, height: height)
            
        }
        
        private let fontScale: CGFloat = 0.75
    }
    
    struct CourtOrAceCenterView: View {
        var card: Card
        var fontSize: CGFloat
        
        var body: some View {
            let text = card.face == .ace ? card.suit.rawValue : card.face.rawValue
            Text(text)
                .foregroundColor(card.suit.suitColor)
                .font(Font.custom("Academy Engraved LET", size: fontSize))
                .baselineOffset((-fontSize / 2))
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            BackgroundView()
            
            VStack {
                Spacer()
                HStack{
                    CardView(card: Card(face: .king, suit: .spade))
                    CardView(card: Card(face: .queen, suit: .heart))
                    CardView(card: Card(face: .jack, suit: .club))
                }
                .frame(height: _28s.cardSize_screenHeight_667.height)
                
                HStack {
                    CardView(card: Card(face: .ace, suit: .heart))
                    CardView(card: Card(face: .ace, suit: .club))
                    CardView(card: Card(face: .ace, suit: .diamond))
                }
                .frame(height: _28s.cardSize_screenHeight_667.height)
                
                HStack{
                    CardView(card: Card(face: .ace, suit: .spade))
                    CardView(card: Card(face: .ten, suit: .heart))
                    CardView(card: Card(face: .nine, suit: .club))
                }
                .frame(height: _28s.cardSize_screenHeight_667.height)
                
                HStack{
                    CardView(card: Card(face: .eight, suit: .diamond))
                    CardView(card: Card(face: .seven, suit: .spade))
                    CardBackView()
                }
                .frame(height: _28s.cardSize_screenHeight_667.height)
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}


