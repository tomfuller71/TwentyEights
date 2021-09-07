//
//  Devices.swift
//  Created by Thomas Fuller
//

import SwiftUI

extension View {
    /// Returns a preview device with a display name  for a given device type
    func previewWith(_ device: IOS_Device) -> some View {
        self
            .previewDevice(IOS_Device.init(rawValue: device.rawValue)?.previewDevice)
            .previewDisplayName(device.rawValue)
    }
    
    /// Returns a preview device with a display name  for a given device type and adds environment var cardSize given the provided view proxy
    func previewFor28sWith(_ device: IOS_Device) -> some View {
        /// Returns the standard card size for a full screen proxy
        let height = device.ui.size.height * _28s.cardToViewHeightRatio
        let width = height * _28s.standardCardWidthRatio
        let cardSize = CGSize(width: width, height: height)
        let fontSize = cardSize.height * _28s.fontCardHeightScale
        let stdFont = Font.custom("Copperplate", fixedSize: fontSize)
        
        return self
            .previewDevice(IOS_Device.init(rawValue: device.rawValue)?.previewDevice)
            .previewDisplayName(device.rawValue)
            .environment(\.cardValues, (size: cardSize, fontSize: fontSize))
            .environment(\.font, stdFont)
    }
}



/// A enum of the standard preview iOS device types
enum IOS_Device: String {
    case iPad = "iPad (8th generation)"
    case iPadAir = "iPad Air (4th generation)"
    case iPadPro_9_7 = "iPad Pro (9.7-inch)"
    case iPadPro_11 = "iPad Pro (11-inch) (3th generation)"
    case iPadPro_12_9 = "iPad Pro (12.9-inch) (5th generation)"
    case iPhone8 = "iPhone 8"
    case iPhone8_Plus = "iPhone 8 Plus"
    case iPhone11 = "iPhone 11"
    case iPhone11_Pro = "iPhone 11 Pro"
    case iPhone11_Pro_Max = "iPhone 11 Pro Max"
    case iPhone12 = "iPhone 12"
    case iPhone12_Pro = "iPhone 12 Pro"
    case iPhone12_Pro_Max = "iPhone 12 Pro Max"
    case iPhone12_mini = "iPhone 12 mini"
    case iPhoneSE_2 = "iPhone SE (2nd generation)"
    
    ///Returns an optional PreviewDevice for the provided IOS_Device type enum
    var previewDevice: PreviewDevice? {
        PreviewDevice(rawValue: self.rawValue)
    }
    
    /// Hold UI information for the IOS device type
    struct UI {
        /// Returns the standard dimensions of the full screen when in portrait mode
        var size: CGSize
        /// Returns the UI dimension to physical screen scalar multiple
        var pxMult: Int
    }
    
    var ui: UI {
        switch self {
        case .iPad:
            return UI(size: CGSize(width: 810, height: 1080), pxMult: 2)
            
        case .iPadAir, .iPadPro_9_7:
            return UI(size: CGSize(width: 768, height: 1024), pxMult: 2)
            
        case .iPadPro_12_9:
            return UI(size: CGSize(width: 1024, height: 1366), pxMult: 2)
            
        case .iPadPro_11:
            return UI(size: CGSize(width: 834, height: 1194), pxMult: 2)
            
        case .iPhone8, .iPhoneSE_2:
            return UI(size: CGSize(width: 375, height: 667), pxMult: 2)
            
        case .iPhone8_Plus:
            return UI(size: CGSize(width: 414, height: 736), pxMult: 3)
            
        case .iPhone11:
            return UI(size: CGSize(width: 414, height: 896), pxMult: 2)
            
        case .iPhone11_Pro, .iPhone12_mini:
            return UI(size: CGSize(width: 375, height: 812), pxMult: 3)
            
        case .iPhone11_Pro_Max:
            return UI(size: CGSize(width: 414, height: 896), pxMult: 3)
            
        case .iPhone12, .iPhone12_Pro:
            return UI(size: CGSize(width: 390, height: 844), pxMult: 3)
        case .iPhone12_Pro_Max:
            return UI(size: CGSize(width: 428, height: 926), pxMult: 2)
        }
    }
}
