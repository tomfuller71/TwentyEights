//
//  StatusView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 12/8/20.
//

import SwiftUI

struct AlertView: View {
    var viewModel: UserView.AlertViewModel
    @Binding var playerAction: PlayerAction.ActionType?
    
    var body: some View {
        ZStack {
            if viewModel.userCanCallTrump {
                Button(action: {
                    playerAction = .callForTrump
                }, label: {
                    Text(viewModel.statusText)
                        .foregroundColor(.lead)
                        .padding([.top,.bottom],3)
                        .padding([.leading,.trailing], 7)
                        .background(
                            Capsule()
                                .fill(Color.offWhite)
                                .background(
                                    Capsule().stroke(Color.black, lineWidth: 2)
                                        .shadow(color: .black, radius: 5, x: 3, y: 5)
                                )
                        )
                })
            }
            else {
                Text(viewModel.statusText)
                    .fixedSize()
                    .foregroundColor(.white)
                    .padding([.top,.bottom],3)
                    .padding([.leading,.trailing], 7)
                    .background(Capsule()
                                    .strokeBorder(Color.offWhite))
            }
        }
        .opacity(viewModel.hideView ? 0 : 1)
        .transition(.opacity)
        .animation(.easeIn(duration: 0.1))
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        
        ZStack {
            BackgroundView()
            VStack {
                AlertView(
                    viewModel: UserView.AlertViewModel(statusText: "Text should be viewable", userCanCallTrump: false, hideView: false),
                    playerAction: .constant(nil)
                )
                
                AlertView(
                    viewModel: UserView.AlertViewModel(statusText: "Text should be overwritten", userCanCallTrump: false, hideView: false),
                    playerAction: .constant(nil)
                )
            }
        }
        .font(.copperPlate)
    }
}
