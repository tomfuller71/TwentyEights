//
//  onPressingDragGesure.swift
//  PressingDragGesture
//
//  Created by Thomas Fuller on 3/24/21.
//

import SwiftUI


extension View {
    /// A view modifier that adds  aPressingDragGesture, which never succeeds, but whose `PressingDragGesture.Value` properties include `.isActive` and `.offset`.
    ///
    ///   When the gesture is not being pressed it will automatically reset to its default `.inactive` state.  Unlike an .updating method of a gesture, the resetting event calls the perform closure,  enabling this change of state to .inactive to be handled and explicitly animated if desired.
    ///
    /// - Parameters:
    ///   - minimumDuration: Optional seconds after press starts that drag is enabled.
    ///   - perform : closure called on change of  `PressingDragGesture.Value` state.
    /// - Returns: A modified view with PressingDragGesture applied
    func onPressingDragGesture(
        minimumDuration: Double? = nil,
        perform: @escaping (PressingDragGesture.Value) -> ()
    ) -> some View {
        
        return self.modifier(
            PressingDragGesture(
                minimumDuration: minimumDuration,
                perform: perform
            )
        )
    }
}


struct PressingDragGesture: ViewModifier {
    var minimumDuration: Double?
    var perform: (PressingDragGesture.Value) -> ()
    
    @GestureState private var dragState: DragGesture.Value?
    @GestureState private var pressState: PressState = PressState()
    
    func body(content: Content) -> some View {
        content.self
            .gesture(pressThenDrag)
            .onChange(of: dragState) { newState in
                
                if let drag = newState {
                    perform(.dragging(drag))
                }
                else if !pressState.pressing {
                    perform(.inactive)
                }
            }
            .onChange(of: pressState) { [pressState] value in
                if pressState.pressing && !value.pressing {
                    perform(.inactive)
                }
                else if !pressState.pressing && value.pressing {
                    perform(.pressing)
                }
            }
    }
    
    private struct PressState: Equatable {
        var pressing: Bool = false
        var dragEnabled: Bool = false
    }
    
    private var pressThenDrag: some Gesture {
        let pressing = LongPressGesture(
            minimumDuration: minimumDuration ?? 0.01,
            maximumDistance: .infinity
        )
            .sequenced(
                before: LongPressGesture(
                    minimumDuration: .infinity,
                    maximumDistance: .infinity)
            )
            .updating($pressState) { pressed, state, _  in
                switch pressed {
                case .first(true):
                    state.pressing = true
                case .second(true, _):
                    state.dragEnabled = true
                default:
                    return
                }
            }
        
        let dragging = DragGesture()
            .updating($dragState) { drag, state, _ in
                if pressState.dragEnabled {
                    state = drag
                }
            }
        
        return pressing.simultaneously(with: dragging)
    }
    /// Enumeration of the Value of a PressingDragGesture
    enum Value: Equatable {
        /// The default gesture  state
        case inactive
        /// The gesture state when the user is actively pressing down
        case pressing
        /// The gesture state when the user is dragging
        /// - Contains the  current `DragGesture.Value` associated with the PressingDrag
        case dragging(DragGesture.Value)
        
        /// Whether the gesture is currently active
        var isActive: Bool {
            switch self {
            case .pressing, .dragging(_):
                return true
            default:
                return false
            }
        }
        /// The current draft offset value (.zero if not dragging)
        var offset: CGSize {
            switch self {
            case .dragging(let drag):
                return drag.translation
            default:
                return .zero
            }
        }
        
        var predictedOffset: CGSize {
            switch self {
            case .dragging(let drag):
                return drag.predictedEndTranslation
            default:
                return .zero
            }
        }
    }
}
