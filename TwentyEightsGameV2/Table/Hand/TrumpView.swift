//
//  TrumpView.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/7/21.
//

import SwiftUI

struct TrumpView: View {
    var trump: Card
    var userActiveAndBidding: Bool
    
    @Environment(\.cardValues) var cardValues
    @Binding var playerAction: PlayerAction.ActionType?
    @State var pressDrag: PressingDragGesture.Value = .inactive
    
    
    var body: some View {
        ZStack {
            CardBackView()
                .flip(isFlipped: pressDrag.isActive, axis: .y) {
                    CardView(card: trump)
                }
        }
        .shadow(color: pressDrag.isActive ? .black : .clear, radius: 5, x: 5, y: 5)
        .frame(width: cardValues.size.width, height: cardValues.size.height)
        .offset(limitOffset)
        .onPressingDragGesture { value in
            if canUnSelect(offset: value.offset) {
                pressDrag = value
                playerAction = .unSelectATrump
            }
            else {
                withAnimation { pressDrag = value }
            }
        }
    }
    
    private var limitOffset: CGSize {
        guard userActiveAndBidding else { return .zero}
        
        return CGSize(
            width: min(pressDrag.offset.width,0),
            height: 0.0
        )
    }
    
    private func canUnSelect(offset: CGSize) -> Bool {
        offset.width < -cardValues.size.width && userActiveAndBidding
    }
}



struct TrumpView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundView()
                
                VStack(spacing: 0) {
                    TrumpView(
                        trump: Card(face: .ace, suit: .spade),
                        userActiveAndBidding: true,
                        playerAction: .constant(nil)
                    )
                }
            }
            .previewFor28sWith(.iPhone8)
            
            ZStack {
                BackgroundView()
                
                VStack(spacing: 0) {
                    TrumpView(
                        trump: Card(face: .ace, suit: .spade),
                        userActiveAndBidding: true,
                        playerAction: .constant(nil)
                    )
                }
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}
