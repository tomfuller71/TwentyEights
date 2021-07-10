//
//  Glow.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/24/21.
//

import SwiftUI

extension View {
    /// Applies a shadow effect twice to give a deeper  glow effect - default color white
    func glow(color: Color = .white, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius / 2)
    }
}
