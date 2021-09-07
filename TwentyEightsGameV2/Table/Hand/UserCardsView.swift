//
//  UserCardsView.swift
//  TwentyEights
//
//  Created by Thomas Fuller
//

import SwiftUI

struct UserCardsView: View {
    var userCards: UserView.UserCardsModel
    @Environment(\.cardValues) var cardValues
    @Binding var playerAction: PlayerAction.ActionType?
    
    var showPlaceholderOnly: Bool { userCards.isBidding && userCards.trump == nil }
    
    var body: some View {
        HStack {
            HandView(handView: userCards, playerAction: $playerAction)
            
            if userCards.isBidding || userCards.trump != nil {
                ZStack {
                    TrumpPlaceHolderView()
                    if let trump = userCards.trump {
                        TrumpView(
                            trump: trump,
                            userActiveAndBidding: userCards.isBidding && userCards.isActive,
                            playerAction: $playerAction
                        )
                    }
                }
                .zIndex(showPlaceholderOnly ? -1 : 1)
            }
        }
        .padding([.leading, .trailing], 7)
    }
    
}

struct UserCardsView_Previews: PreviewProvider {
    static var previews: some View {
        let hand = _28sPreviewData.hand
        let eligible = hand.filter { $0.suit == .heart }
        
        let handView = UserView.UserCardsModel(hand: hand, eligibleCards: eligible, trump: nil, isBidding: true)
        
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
            BackgroundView()
            UserCardsView(userCards: handView, playerAction: .constant(nil))
                .padding([.leading, .trailing, .bottom], 7)
        }
        .previewFor28sWith(.iPhone8)
        
    }
}
