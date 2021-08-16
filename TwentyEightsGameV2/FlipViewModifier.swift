//
//  AnimatableModifer + Flip.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/21/21.
//

import SwiftUI


extension View {
    /// Applies an animatable view modifier that "flips" to show a different reverse view while rotating by 180 degrees when the isFlipped state change is explicity animated
    ///
    /// - Parameters:
    ///   - isFlipped: If `isFlipped` the reverse view will be shown
    ///   - axis: The rotation axis (.x, .y, .z)
    ///   - reverse: an @ViewBuilder function that returns the "reverse" or flipped view
    /// - Returns: A view
    func flip<T>(
        isFlipped: Bool,
        axis: Flip<T>.RotationAxis,
        @ViewBuilder reverse: @escaping () -> T
    ) -> some View where T: View {
        
        return self.modifier(Flip(isFlipped: isFlipped, axis: axis, reverse: reverse))
    }
}

/// A animatable view modifier that "flips" to show a different reverse view while rotating by 180 degrees when the isFlipped state change is explicity animated
///
/// - Parameters:
///   - isFlipped: If `isFlipped` the reverse view will be shown
///   - axis: The rotation axis (.x, .y, .z)
///   - reverse: an @ViewBuilder function that returns the "reverse" or flipped view
/// - Returns: A view
struct Flip<Reverse>: AnimatableModifier where Reverse: View {
    var reverse: () -> Reverse
    var rotation: Double
    var axis: RotationAxis
    var flipped: Bool { rotation > 90 }
    
    init(
        isFlipped: Bool,
        axis: RotationAxis,
        @ViewBuilder reverse: @escaping () -> Reverse
    ) {
        self.rotation = isFlipped ? 180 : 0
        self.axis = axis
        self.reverse = reverse
    }
    
    var animatableData: Double {
        get { rotation }
        set { rotation = newValue }
    }
    
    func body(content: Content) -> some View {
        Group {
            if !flipped {
                content.transition(.identity)
            }
            else {
                reverse().transition(.identity)
                    .rotation3DEffect(.degrees(180), axis: axis.value)
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: axis.value)
    }
    
    enum RotationAxis {
        case x, y, z
        var value: (CGFloat, CGFloat, CGFloat) {
            switch self {
                case .x: return (1,0,0)
                case .y: return (0,1,0)
                case .z: return (0,0,1)
            }
        }
    }
}
