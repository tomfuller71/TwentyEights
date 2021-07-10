//
//  TableBackgroundView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 11/17/20.
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
