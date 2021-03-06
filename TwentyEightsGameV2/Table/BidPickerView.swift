//
//  BidPickerView.swift
//  TwentyEights
//
//  Created by Tom Fuller
//

import SwiftUI

/// View providing UI response to user bidding
struct BidPickerView: View {
    var picker: UserView.BidPickerModel
    var defaultFontSize: CGFloat
    var hideView: Bool
    @Binding var userBidIntent: PlayerAction.ActionType?
    @State var currentBid: Int = 0
    
    
    init(picker: UserView.BidPickerModel, defaultFontSize: CGFloat, hideView: Bool, playerAction: Binding<PlayerAction.ActionType?>) {
        self.picker = picker
        self.defaultFontSize = defaultFontSize
        self.hideView = hideView
        self._userBidIntent = playerAction
        BidPickerView.configPickerWithUIKit(fontSize: defaultFontSize * 1.2)
    }
    
    var body: some View {
    
        VStack(spacing: 0) {
            pickerView

            // Bid & Pass Buttons
            HStack {
                Button(
                    action: { userBid() },
                    label: { bidLabel }
                )
                .padding([.trailing], 20)
                .disabled(!userCanBid)
                
                Button(
                    action: { userPass() },
                    label: { passLabel }
                )
                .disabled(!picker.canPass)
            }
        }
        .opacity(hideView ? 0 : 1)
        .disabled(hideView)
        .font(Font.custom("Academy Engraved LET", fixedSize: defaultFontSize * 1.3))
    }

    /// The UI picker element
    private var pickerView: some View {
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
            .onChange(
                of: picker.minBid,
                perform: { newMin in currentBid = newMin }
            )
            .onAppear {
                currentBid = picker.minBid
            }
            
            Divider()
                .frame(height: 1.5)
                .background(Color.offWhite)
        }
        .frame(width: CGFloat(picker.pickerValues.count) * segmentWidth)
        .padding([.bottom], 10)
    }
    
    /// The width for each segment of picker based on number of segments
    private var segmentWidth: CGFloat {
        switch picker.pickerValues.count {
        case 0 ... 3:   return 60
        case 4 ... 5:   return 50
        case 6 ... 7:   return 45
        default:        return 40
        }
    }
    
    private var userCanBid: Bool { picker.canBid && currentBid >= picker.minBid }
    
    /// Make the bid for the user
    private func userBid() {
        withAnimation {
            userBidIntent = .makeBid(
                Bid(
                    points: currentBid,
                    card: picker.trump!,
                    bidder: picker.seat
                )
            )
        }
    }
    
    private var bidLabel: some View {
        Text("Bid")
            .baselineOffset(-2)
            .foregroundColor(userCanBid ? Color.lemon : Color.gray)
            .opacity(userCanBid ? 1 : 0.5)
    }
    
    private func userPass() {
        withAnimation {
            userBidIntent = .pass(stage: picker.stage)
        }
    }
    
    private var passLabel: some View {
        Text("Pass")
            .baselineOffset(-2)
            .foregroundColor(picker.canPass ? Color.lemon : Color.gray)
            .opacity(picker.canPass ? 1 : 0.5)
    }
}

struct BidPickerView_Previews: PreviewProvider {
    static var previews: some View {
        
        let picker = UserView.BidPickerModel(
            seat: .south,
            pickerValues: Array<Int>(14...20),
            canBid: true,
            canPass: true
        )
        
        ZStack{
            BackgroundView()
            
            BidPickerView(
                picker: picker,
                defaultFontSize: 129.5 * _28s.fontCardHeightScale,
                hideView: false,
                playerAction: .constant(nil)
            )
        }
        .edgesIgnoringSafeArea(.all)
        .previewFor28sWith(.iPhone8)
    }
}


extension BidPickerView {
    
    /// Used  as SwiftUI doesn't have segmentControl so using UIKit settings on view .init
    static func configPickerWithUIKit(fontSize: CGFloat) {
        let font = UIFont(name: "Academy Engraved LET", size: fontSize)!
        
        UISegmentedControl
            .appearance()
            .setBackgroundImage(UIImage.clearW1H32, for: .normal, barMetrics: .default)
        
        UISegmentedControl.appearance()
            .setTitleTextAttributes([.foregroundColor: UIColor.lemon, .font: font],for: .selected)
        
        UISegmentedControl.appearance()
            .setTitleTextAttributes([.foregroundColor: UIColor.offWhite, .font: font],for: .normal)
    }
}


