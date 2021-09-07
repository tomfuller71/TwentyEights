//
//  AlertView.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import SwiftUI

struct AlertView: View {
    var viewModel: UserView.AlertViewModel
    @Binding var playerAction: PlayerAction.ActionType?
    
    var body: some View {
        ZStack {
            Button(
                action: { playerAction = .callForTrump },
                label: { buttonLabel }
            )
            .disabled(!viewModel.userCanCallTrump)
        }
        .opacity(viewModel.hideView ? 0 : 1)
        .animation(.easeIn(duration: 0.1))
    }
    
    private var buttonLabel: some View {
        Text(viewModel.statusText)
            .foregroundColor(viewModel.userCanCallTrump ? Color.lead : .offWhite)
            .padding([.top,.bottom],3)
            .padding([.leading,.trailing], 7)
            .background(
                Capsule()
                    .fill(viewModel.userCanCallTrump ? Color.offWhite : .clear,
                          strokeBorder: viewModel.userCanCallTrump ? Color.black: .white)
                    .shadow(color: viewModel.userCanCallTrump ? Color.black : .clear,
                            radius: 5, x: 3, y: 5)
            )
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        
        Group {
            ZStack {
                BackgroundView()
                VStack {
                    AlertView(
                        viewModel: UserView.AlertViewModel(
                            statusText: "Text should be viewable",
                            userCanCallTrump: false, hideView: false),
                        playerAction: .constant(nil)
                    )
                }
            }
            .previewFor28sWith(.iPhone8)
            
            ZStack {
                BackgroundView()
                VStack {
                    AlertView(
                        viewModel: UserView.AlertViewModel(
                            statusText: "Text should be viewable",
                            userCanCallTrump: false, hideView: false),
                        playerAction: .constant(nil)
                    )
                }
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}
