//
//  BidPickerView.swift
//  TwentyEights
//
//  Created by Tom Fuller on 11/25/20.
//

import SwiftUI

/// View providing UI response to user bidding
struct BidPickerView: View {
    var picker: UserView.BidPickerModel
    @Binding var userBidIntent: PlayerAction.ActionType?
    @State var currentBid: Int = 0
    
    init(picker: UserView.BidPickerModel, playerAction: Binding<PlayerAction.ActionType?>) {
        // Default for now until set by call when Bid process complete
        self.picker = picker
        self._userBidIntent = playerAction
        
        // Default used only as SwiftUI doesn't have segmentControl so setting on view .init
        let font = UIFont(name: "Academy Engraved LET", size: 22)!
        UISegmentedControl
            .appearance()
            .setBackgroundImage(UIImage.clearW1H32, for: .normal, barMetrics: .default)
        UISegmentedControl.appearance()
            .setTitleTextAttributes([.foregroundColor: UIColor.lemon, .font: font],for: .selected)
        UISegmentedControl.appearance()
            .setTitleTextAttributes([.foregroundColor: UIColor.offWhite, .font: font],for: .normal)
    }
    
    var body: some View {
       
        VStack(spacing: 0) {
            //Picker for eligible bids
            VStack(spacing: 0) {
                Divider().frame(height: 1.5)
                    .background(Color.offWhite)
                    .padding([.bottom],7)
                
                Picker("Picker", selection: $currentBid) {
                    ForEach(picker.pickerValues, id: \.self) { value in
                        Text("\(value)")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(Color.clear)
                .onChange(of: picker.minBid, perform: { newMin in
                    currentBid = newMin
                })
                .onAppear {
                    currentBid = picker.minBid
                }
                
                Divider()
                    .frame(height: 1.5)
                    .background(Color.offWhite)
            }
            .frame(width: CGFloat(picker.pickerValues.count) * segmentWidth)
            .padding([.bottom], 10)
            
            // Bid Buttons
            HStack {
                //Bid Button
                Button(
                    action:
                        {
                            if picker.canBid && currentBid >= picker.minBid {
                                withAnimation {
                                    // Bid has to be the min Bid to be valid
                                    userBidIntent = .makeBid(
                                        Bid(
                                            points: currentBid,
                                            card: picker.trump!,
                                            stage: picker.stage)
                                    )
                                }
                            }
                        },
                    label: {
                        Text("Bid")
                            .baselineOffset(-2)
                            .foregroundColor(picker.canBid ? Color.lemon : Color.gray)
                            .opacity(picker.canBid ? 1 : 0.5)
                    }
                )
                .padding([.trailing], 20)
                
                // Pass Button
                Button(
                    action: {
                        if picker.canPass {
                            withAnimation {
                                userBidIntent = .pass(stage: picker.stage)
                            }
                        }
                    },
                    label: {
                        Text("Pass")
                            .baselineOffset(-2)
                            .foregroundColor(picker.canPass ? Color.lemon : Color.gray)
                            .opacity(picker.canPass ? 1 : 0.5)
                    }
                )
            }
            .font(Font.custom("Academy Engraved LET", size: 22))
        }
    }
    
    private var segmentWidth: CGFloat {
        switch picker.pickerValues.count {
        case 0 ... 3:   return 60
        case 4 ... 5:   return 50
        case 6 ... 7:   return 45
        default:        return 40
        }
    }
}

struct BidPickerView_Previews: PreviewProvider {
    static var previews: some View {
        
        ZStack{
            BackgroundView()
            
            BidPickerView(
                picker: UserView.BidPickerModel(
                    pickerValues: Array<Int>(14...20),
                    canBid: true,
                    canPass: true,
                    hideView: false
                ),
                playerAction: .constant(nil)
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}


