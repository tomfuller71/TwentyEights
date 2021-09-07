//
//  BackgroundView.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import SwiftUI

struct BackgroundView: View {
    // Style local vars - move to seperate Style struct if become more frequent
    
    var body: some View {
        LinearGradient.mossSteel
            .edgesIgnoringSafeArea(.all)
    }
}

struct BackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundView()
    }
}
