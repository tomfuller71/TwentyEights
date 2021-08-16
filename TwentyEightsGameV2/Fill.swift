//
//  fill.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 7/14/21.
//

import SwiftUI

// Thanks to twoStaws for code
// https://www.hackingwithswift.com/quick-start/swiftui/how-to-fill-and-stroke-shapes-at-the-same-time

extension Shape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(
        _ fillStyle: Fill,
        strokeBorder strokeStyle: Stroke,
        lineWidth: CGFloat = 1
    ) -> some View {
        
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

extension InsettableShape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(
        _ fillStyle: Fill,
        strokeBorder strokeStyle: Stroke,
        lineWidth: CGFloat = 1
    ) -> some View {
        
        self
            .strokeBorder(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}
