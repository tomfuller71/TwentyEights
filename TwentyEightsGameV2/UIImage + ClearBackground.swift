//
//  Clear Background.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/24/21.
//

import SwiftUI

// Using this code from rMaddy on StackOverflow to create transparent Image of given size
extension UIImage {
    
    static let clearW1H32 = UIImage(color: .clear, size: CGSize(width: 1, height: 32))
    
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        color.set()
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        self.init(data: image.pngData()!)!
    }
}
