//
//  File.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 3/1/21.
//

import Foundation

@propertyWrapper
struct IntID {
    static var count: Int = 0
    
    private var id: Int
    
    init() {
        self.id = IntID.count
        IntID.count += 1
    }
    
    var wrappedValue: Int {
        get { self.id }
    }
}
