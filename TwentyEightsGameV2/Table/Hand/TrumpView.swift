//
//  TrumpView.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/7/21.
//

import SwiftUI

struct TrumpView: View {
    var trump: Card
    var isBidding: Bool
    var cardSize: CGSize
    var isActive: Bool
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
        guard isActive && isBidding else { return .zero}
        
        return CGSize(
            width: min(pressDrag.offset.width,0),
            height: 0.0
        )
    }
    
    private func canUnSelect(offset: CGSize) -> Bool {
        offset.width < -cardSize.width && isActive && isBidding
    }
}



struct TrumpView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            
            VStack(spacing: 15) {
                TrumpView(
                    trump: Card(face: .ace, suit: .spade),
                    isBidding: true,
                    cardSize: _28s.cardSize_screenHeight_667,
                    isActive: true,
                    playerAction: .constant(nil)
                )
            }
            .frame(width: _28s.cardSize_screenHeight_667.width, height: _28s.cardSize_screenHeight_667.height)
        }
    }
}
