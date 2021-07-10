//
//  TrumpCalled.swift
//  JokerGame
//
//  Created by Tom Fuller on 12/30/20.
//

import SwiftUI

struct TrumpCalled: View {
    var trump: Card
    @Binding var caller: Seat?

    
    var body: some View {
        VStack {
            if let caller = caller {
                Text("\(caller.name) asked")
            }
            Text("for trump")
                .foregroundColor(.black)
            
            CardView(card: trump)
                .frame(height: 100)
        }
        .onTapGesture {
            caller = nil
        }
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + _28s.uiDelay * 2) {
                caller = nil
            }
        })
        
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25.0)
                .fill(Color.offWhite)
                .shadow(color: .black, radius: 5, x: 3, y: 5)
        )
    }
}

struct TrumpCalled_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            
            TrumpCalled(trump: Card(face: .ace, suit: .heart), caller: .constant(.south))
        }
        .font(.copperPlate)
    }
}
