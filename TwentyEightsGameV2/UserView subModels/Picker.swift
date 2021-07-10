//
//  Picker.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/24/21.
//

import SwiftUI

extension UserView {
    /// Model of the properties in a BidPickerView
    struct BidPickerModel {
        var pickerValues: [Int] = []
        var minBid: Int = Bidding.BiddingStage.first.minimumBid
        var canBid: Bool = false
        var canPass: Bool = false
        var hideView: Bool = true
    }
    
    /// Returns updated picker sub-view model
    private func updateBidPicker() -> BidPickerModel{
        guard (userIsActive && isBidding) else { return BidPickerModel() }
        
        var maxBid: Int {
            var max = game.round.bidding.stage.maximumBid
            if game.round.topBid.points >= max {
                max = Bidding.BiddingStage.second.maximumBid
            }
            return max
        }
        
        var minBid: Int { game.round.bidMinForSeat(userSeat) }
        
        return BidPickerModel(
            pickerValues: Array(minBid ... maxBid),
            canBid: userHasTrump,
            canPass: canPass,
            hideView: !isBidding
        )
    }
    
}
