//
//  ParentSizeEnvironmentKey.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 8/23/21.
//

import Foundation
import SwiftUI

struct CardValuesEnvironmentKey: EnvironmentKey {
    typealias Value = (size: CGSize, fontSize: CGFloat)
    
    static let defaultValue:(size: CGSize, fontSize: CGFloat) = (size: .zero, fontSize: 0)
}

extension EnvironmentValues {
    var cardValues: (size: CGSize, fontSize: CGFloat) {
        get { self[CardValuesEnvironmentKey.self] }
        set { self[CardValuesEnvironmentKey.self] = newValue }
    }
}

