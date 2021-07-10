//
//  UserCardsView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/18/21.
//

import SwiftUI

struct UserCardsView: View {
    var userCards: UserView.UserCardsModel
    var cardSize: CGSize
    @Binding var playerAction: PlayerAction.ActionType?
    
    var body: some View {
        HStack {
            HandView(handView: userCards, cardSize: cardSize, playerAction: $playerAction)
            
            if userCards.isBidding || userCards.trump != nil {
                ZStack {
                    TrumpPlaceHolderView(cardSize: cardSize)
                    if let trump = userCards.trump {
                        TrumpView(
                            trump: trump,
                            isBidding: userCards.isBidding,
                            cardSize: cardSize,
                            isActive: userCards.isActive,
                            playerAction: $playerAction
                        )
                    }
                }
                .zIndex(showPlaceholderOnly ? -1 : 1)
                .frame(width: cardSize.width)
            }
        }
        .frame(height: cardSize.height)
    }
    
    var showPlaceholderOnly: Bool { userCards.isBidding && userCards.trump == nil }
}

struct UserCardsView_Previews: PreviewProvider {
    static var previews: some View {
        let hand = _28sPreviewData.hand
        let eligible = hand.filter { $0.suit == .heart }
        
        let handView = UserView.UserCardsModel(hand: hand, eligibleCards: eligible, trump: nil, isBidding: true)
        
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
            BackgroundView()
            UserCardsView(userCards: handView, cardSize:_28s.cardSize_screenHeight_667, playerAction: .constant(nil))
                .padding([.leading, .trailing, .bottom], 7)
        }
        
    }
}
