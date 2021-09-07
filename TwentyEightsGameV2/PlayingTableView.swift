//
//  PlayingTableView.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import SwiftUI

struct PlayingTableView: View {
    @EnvironmentObject var user: UserView
    @State var showStageChange = false
    @State var calledTrumpSeat: Seat?
    
    var body: some View {
        GeometryReader { proxy in
            let cardValues = getCardValues(proxy: proxy)
            
            ZStack {
                BackgroundView()
                
                VStack(spacing: 0) {
                    ScoresView(scores: user.scores)
                    
                    Spacer()
                    
                    SeatView(seats: user.seats)
                        .offset(y: -10)
                    
                    Spacer()
                    
                    BidPickerView(
                        picker: user.picker,
                        defaultFontSize: cardValues.fontSize,
                        hideView: !user.userIsActive || !user.isBidding ,
                        playerAction: $user.playerAction
                    )
                    
                    Spacer()
                    
                    AlertView(viewModel: user.alerts, playerAction: $user.playerAction)
                    
                    Spacer()
                    
                    UserCardsView(
                        userCards: user.userCards,
                        playerAction: $user.playerAction
                    )
                }
                .padding([.bottom],7)
                // Limit width (8 cards + trump + spacers)
                .frame(maxWidth: getMaxHandWidth(cardSize: cardValues.size))
                
                //MARK: - Condtional Views
                VStack(alignment: .center) {
                    if showStageChange {
                        stageChangeView
                    }
                    
                    if calledTrumpSeat != nil {
                        TrumpCalled(
                            trump: user.roundTrump!,
                            caller: $calledTrumpSeat
                        )
                        .transition(.opacity)
                    }
                }
            }
            // Add std values for the card CGSize and font CGFloat size into environment
            .environment(\.cardValues, cardValues)
            .environment(\.font, defaultFontOf(fontSize: cardValues.fontSize))
        }
        
        //MARK: - onChange
        .onChange(of: user.gameStage) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                withAnimation {
                    showStageChange = true
                }
            }
        }
        .onChange(of: user.seatJustCalledTrump) { seat in
            if seat != nil {
                withAnimation {
                    calledTrumpSeat = seat
                }
            }
        }
        //MARK: - Set up onAppear
        .onAppear {
            if user.gameStage == .playingRound(.starting) && user.userIsActive {
                withAnimation {
                    user.playerAction = .startNewRound
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

extension PlayingTableView {
    
    @ViewBuilder
    private var stageChangeView: some View {
        Group {
            switch user.gameStage {
            case .playingRound(.ending):
                EndRoundView(
                    userTeamWon: user.game.round.winningTeam == user.userSeat.team,
                    updatedTeamScore: user.game.scores[.player]!,
                    gamePoints: user.game.round.getGamePoints(),
                    action: $user.playerAction,
                    showView: $showStageChange)
                    .transition(.opacity)
                
            case .playingRound(let roundStage):
                StageChangeView(stage: roundStage, showView: $showStageChange)
                    .transition(.slide)
                
            case .endingGame:
                EndGameView(userTeamWins: user.userTeamWon, action: $user.playerAction)
                    .transition(.opacity)
            }
        }
    }
    
    /// Returns tuple standard dimensions for a playing card  and std font size (will change  based on device type)
    private func getCardValues(proxy: GeometryProxy) -> CardValuesEnvironmentKey.Value {
        let cardHeight: CGFloat = proxy.size.height * _28s.cardToViewHeightRatio
        let cardWidth: CGFloat = cardHeight * _28s.standardCardWidthRatio
        
        return (
            size: CGSize(width: cardWidth, height: cardHeight),
            fontSize: cardHeight * _28s.fontCardHeightScale
        )
    }
    
    /// Returns the maxWidth frame limit (constrains width on Ipads)
    private func getMaxHandWidth(cardSize: CGSize) -> CGFloat {
        // card width * (inital + spacers) + trump Placeholder
        ( cardSize.width + _28s.uiSpacerBetweenCards)
            * ( CGFloat(_28s.initalHandSize)  )
            + cardSize.width
    }
    
    /// The defaullt fixed scale font for the app
    private func defaultFontOf(fontSize: CGFloat ) -> Font {
        Font
            .custom("Copperplate", fixedSize: fontSize)
            .weight(.light)
    }
}

struct PlayingTableView_Previews: PreviewProvider {
    
    static var previews: some View {
        let user: UserView = {
            let game = GameController(players: _28s.players)
            let user = UserView(game: game)
            return user
        }()
        
        Group {
            PlayingTableView()
                .previewWith(.iPhone8)
                .environmentObject(user)
        }
    }
}
