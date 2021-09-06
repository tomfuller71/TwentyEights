//
//  HandView.swift
//  JokerGame
//
//  Created by Tom Fuller on 12/25/20.
//

import SwiftUI

struct HandView: View {
    //MARK:- Properties
    var handView: UserView.UserCardsModel
    @Environment(\.cardValues) var cardValues
    
    @Binding var playerAction: PlayerAction.ActionType?
    @State private var pressDrag: [String : PressingDragGesture.Value] = [:]
    
    //MARK:- View Body
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(handView.hand) { card in
                    let modify = pressDrag[card.id]?.isActive ?? false
                    let position = getPosition(for: card, with: proxy)
                    let offset = limitOffset(pressDrag[card.id]?.offset ?? .zero)
                    
                    CardView(card: card)
                        .modifier(ModifyCard(modify: modify, position: position, offset: offset))
                        .onPressingDragGesture { value in
                            update(
                                gesture: value,
                                position: position,
                                handWidth: proxy.size.width,
                                card: card
                            )
                        }
                }
            }
        }
        .frame(height: cardValues.size.height)
        .onAppear {
            for card in handView.hand {
                pressDrag[card.id] = .inactive
            }
        }
    }
    
    //MARK: - Private view properties
    private let spacer: CGFloat = _28s.uiSpacerBetweenCards
    
    ///View modifier to apply the various conditional view modifiers
    private struct ModifyCard: ViewModifier {
        var modify: Bool
        var position: CGPoint
        var offset: CGSize
        
        func body(content: Content) -> some View {
            content
                .shadow(color: modify ? .clear : .black, radius: 5, x: 5, y: 5)
                .scaleEffect(modify ? 1.1 : 1)
                .zIndex(modify ? 1 : 0)
                .position(position)
                .offset(offset)
                .animation(.default)
        }
    }
}


//MARK:- View methods
extension HandView {
    /// Limit x / y movement of the cards depending on dragLimits set based on on stage of game
    private func limitOffset(_ drag: CGSize) -> CGSize {
        if handView.isBidding {
            return CGSize(width: max(0, drag.width), height: 0)
        }
        else {
            return CGSize(width: drag.width, height: min(0, drag.height))
        }
    }
    
    /// Update the card gesture state and check for actions
    private func update(
        gesture: PressingDragGesture.Value,
        position: CGPoint,
        handWidth: CGFloat,
        card: Card
    ) {
        guard handView.iseligibleToPlay(card) else { return }
        
        var cardSelected = false
        if gesture.offset != .zero {
            if handView.isBidding {
                cardSelected = gesture.offset.width > ((handWidth - position.x) + cardValues.size.width / 2)
            }
            else {
                cardSelected = gesture.offset.height < -cardValues.size.height ||
                                    gesture.predictedOffset.height < -cardValues.size.height * 2
            }
        }
        
        if cardSelected {
            print("Taking Action \(card.id)")
            pressDrag[card.id] = .inactive
            if playerAction == nil {
                playerAction = handView.isBidding ? .selectATrump(card) : .playCardInTrick(card)
            }
        }
        else {
            pressDrag[card.id] = gesture
        }
    }
    
    /// Returns the CGPoint of a given card in a hand when not subject to a gesture
    private func getPosition(for card: Card, with proxy: GeometryProxy) -> CGPoint {
        //Set up position if card not active
        let indexAsFloat = CGFloat(index(of: card))
        let countAsFloat = CGFloat(handView.hand.count)
        
        // delta to view width to the ideal spacing for the cards in hand
        let viewWidthDelta = (cardValues.size.width * countAsFloat) + (spacer * (countAsFloat - 1)) - proxy.size.width
        
        // Preparing per card return values
        let overLap = (viewWidthDelta > 0) ? viewWidthDelta / (countAsFloat - 1) : 0
        let initial = (viewWidthDelta < 0) ? (viewWidthDelta / 2 * -1) + (cardValues.size.width / 2) : cardValues.size.width / 2
        let perCard =  cardValues.size.width + spacer - overLap
        
        // Complete the inHand CGPoint position
        let yposition: CGFloat = (proxy.size.height / 2)
        let xposition: CGFloat = initial + (perCard * indexAsFloat)
        let inHandPositon = CGPoint(x: xposition, y: yposition)
        
        return inHandPositon
    }
    
    /// Returns the index of a given card in the cards array
    private func index(of card: Card) -> Int {
        handView.hand.firstIndex(of: card)!
    }
}
    

//MARK:- Preview
struct HandView_Previews: PreviewProvider {
    static var previews: some View {
        let hand = _28sPreviewData.hand
        let eligible = hand.filter { $0.suit == .heart }
        let handView = UserView.UserCardsModel(hand: hand, eligibleCards: eligible, trump: nil, isBidding: false)
        
        Group {
            ZStack {
                BackgroundView()
                
                VStack {
                    HandView(handView: handView, playerAction: .constant(nil) )
                }
                .padding([.leading, .trailing], 7)
            }
            .previewFor28sWith(.iPhone8)
            
            ZStack {
                BackgroundView()
                
                VStack {
                    HandView(handView: handView, playerAction: .constant(nil) )
                }
                .padding([.leading, .trailing], 7)
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}


