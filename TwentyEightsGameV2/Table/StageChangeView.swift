//
//  StageChangeView.swift
//  JokerGame
//
//  Created by Tom Fuller on 1/12/21.
//

import SwiftUI

struct StageChangeView: View {
    var stage: Round.RoundStage
    @Binding var showView: Bool
    
    var body: some View {
        Text(stage.textDescription)
            .fontWeight(.bold)
            .foregroundColor(.lead)
            .padding()
            .background(
                Capsule()
                    .fill(Color.offWhite)
                    .shadow(color: .black, radius: 5, x: 3, y: 5)
            )
            .onTapGesture {
                showView = false
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay) {
                    withAnimation {
                        showView = false
                    }
                }
            }
    }
}

struct StageChangeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            StageChangeView(stage: .starting, showView: .constant(true))
        }
        .previewFor28sWith(.iPhone8)
    }
}
