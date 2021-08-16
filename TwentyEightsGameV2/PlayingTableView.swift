//
//  BidView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 12/1/20.
//

import SwiftUI

struct PlayingTableView: View {
    @EnvironmentObject var user: UserView
    @State var showStageChange = false
    @State var calledTrumpSeat: Seat?
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            GeometryReader { proxy in
                /// Standard dimensions for a playing card (will change  based on device type)
                let cardSize: CGSize = getCardSizeForScreen(proxy: proxy)
                
                VStack(spacing: 0) {
                    ScoresView(scores: user.scores)
                    
                    SeatView(seats: user.seats, cardSize: cardSize)
                    
                    BidPickerView(picker: user.picker, playerAction: $user.playerAction)
                    .opacity(user.userIsActive && user.isBidding ? 1 : 0)
                    
                    AlertView(viewModel: user.alerts, playerAction: $user.playerAction)
                    .padding([.bottom], 5)
                    
                    UserCardsView(
                        userCards: user.userCards,
                        cardSize: cardSize,
                        playerAction: $user.playerAction
                    )
                    .padding([.leading, .trailing], 5)
                }
                .padding([.bottom],7)
            }
            //MARK: - Condtional Views
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
        //MARK: - Environment settings
        .environment(\.font, .copperPlate)
        
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
    }
}



extension PlayingTableView {
    
    @ViewBuilder
    private var stageChangeView: some View {
        Group {
            switch user.gameStage {
            case .playingRound(.ending):
                EndRoundView(
                    userTeamWon: user.game.round.winningTeam == user.userSeat.partnerGroup,
                    gamePoints: _28s.gamePointsForBidOf(user.scores.bid.bidPoints),
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
    
    /// Returns the standard card size for a full screen proxy
    func getCardSizeForScreen(proxy: GeometryProxy) -> CGSize {
        let cardHeight: CGFloat = proxy.size.height * 0.20
        let cardWidth: CGFloat = cardHeight * _28s.standardCardWidthRatio
        return CGSize(width: cardWidth, height: cardHeight)
    }
}

struct PlayingTableView_Previews: PreviewProvider {
    
    static var previews: some View {
        let user: UserView = {
            let game = GameController(players: _28s.players)
            let user = UserView(game: game)
            return user
        }()
        
        PlayingTableView().environmentObject(user)
    }
}
