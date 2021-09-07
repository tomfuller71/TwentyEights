//
//  TrumpCalled.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import SwiftUI

struct TrumpCalled: View {
    var trump: Card
    @Binding var caller: Seat?
    @Environment(\.cardValues) var cardValues

    
    var body: some View {
        VStack {
            VStack{
                if let caller = caller {
                    Text("\(caller.name) asked")
                    Text("for Trump")
                }
            }
            .foregroundColor(.black)
            
            CardView(card: trump).scaleEffect(0.8)
        }
        .padding()
        .frame(minWidth: cardValues.size.width * 1.75)
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
            RoundedRectangle(cornerRadius: cardValues.size.width * 0.33)
                .fill(Color.offWhite)
                .shadow(color: .black, radius: 5, x: 3, y: 5)
        )
    }
}

struct TrumpCalled_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundView()
                
                TrumpCalled(trump: Card(face: .ace, suit: .heart), caller: .constant(.south))
            }
            .previewFor28sWith(.iPhone12)
            
            ZStack {
                BackgroundView()
                
                TrumpCalled(trump: Card(face: .ace, suit: .heart), caller: .constant(.south))
            }
            .previewFor28sWith(.iPadPro_12_9)
        }
    }
}
