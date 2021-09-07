//
//  AppUIStyle.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import SwiftUI

// Adding default for the project
extension Font {
    static let copperPlate = Font.custom("Copperplate", fixedSize: 20).weight(.light)
}

enum ProjectFont: String {
    case copperPlate
    case academy = "Academy Engraved LET"
}

extension View {
    func font(_ font: ProjectFont, size: CGFloat) -> some View {
        self.font(.custom(font.rawValue, size: size)
                    .weight(font == .copperPlate ? .light : .regular)
        )
    }
}


// Adding scheme colors into Color Struct
extension Color {
    static let offWhite = Color(red: 225 / 255, green: 225 / 255, blue: 235 / 255)
    static let cayenne = Color(#colorLiteral(red: 0.5807225108, green: 0.066734083, blue: 0, alpha: 1))
    static let moss = Color(#colorLiteral(red: 0, green: 0.5628422499, blue: 0.3188166618, alpha: 1))
    static let lead = Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1))
    static let mercury = Color(#colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1))
    static let iron = Color(#colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1))
    static let lemon = Color(#colorLiteral(red: 0.7848167109, green: 0.746216685, blue: 0.0008920759827, alpha: 1))
    static let darkGreen = Color(#colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 1))
}

// UIKit colors used in BidPicker UIPicker View
extension UIColor {
    static let offWhite: UIColor = UIColor(
        red: 225 / 255,
        green: 225 / 255,
        blue: 235 / 255,
        alpha: 1.0
    )
    
    static let lemon: UIColor = UIColor(
        red: 0.7848167109,
        green: 0.746216685,
        blue: 0.0008920759827,
        alpha: 1
    )
}


extension AngularGradient {
    static let cayenneSteel = AngularGradient(
        gradient: Gradient(colors: [.lead, .cayenne, .lead, .cayenne, .lead, .cayenne, .lead]),
        center: .center
    )
    
    static let steel = AngularGradient(
        gradient: Gradient(colors:[ .iron, .mercury, .iron, .mercury, .iron]),
        center: .center
    )
}

extension LinearGradient {
    
    static let mossSteel = LinearGradient(
        gradient: Gradient(colors:[.lead, .moss]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkSteel = LinearGradient(
        gradient: Gradient(colors:[ .lead, .iron]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gold = LinearGradient(
        gradient: Gradient(
            colors: [
                Color(red: 235 / 255, green: 209 / 255, blue: 151 / 255, opacity: 1.0),
                Color(red: 180 / 255, green: 136 / 255, blue: 17 / 255, opacity: 1.0),
                Color(red: 162 / 255, green: 121 / 255, blue: 13 / 255, opacity: 1.0),
                Color(red: 187 / 255, green: 155 / 255, blue: 73 / 255, opacity: 1.0),
                Color.white
            ]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}





