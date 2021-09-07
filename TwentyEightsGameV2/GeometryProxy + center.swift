//
//  GeometryProxy +.swift
//  Created by Thomas Fuller
//

import Foundation
import SwiftUI

extension GeometryProxy {
    /// The center GGPoint within the proxy size CGRect
    var center: CGPoint { CGPoint(x: self.size.width / 2 , y: self.size.height / 2) }
}
