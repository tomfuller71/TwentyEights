//
//  ActiveSeatIndictorView.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/18/21.
//

import SwiftUI

struct ActiveSeatIndictorView: View {
    var indicatorAngle: Angle
    var size: CGFloat
    var body: some View {
        Image(systemName: "location.north.fill")
            .foregroundColor(.offWhite)
            .scaleEffect(size)
            .rotationEffect(indicatorAngle)
            .animation(.default)
            .opacity(0.8)
    }
}

struct ActiveSeatIndictorView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            ActiveSeatIndictorView(indicatorAngle: .degrees(90), size: 1)
        }
    }
}
