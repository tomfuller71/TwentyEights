//
//  TwentyEightsGameV2App.swift
//  TwentyEightsGameV2
//
//  Created by Thomas Fuller on 2/26/21.
//

import SwiftUI

@main
struct TwentyEightsGameV2App: App {
    let game: GameController
    let cpuPlayer: CPUPlayer
    let user: UserView
    
    init() {
        self.game = GameController(players: _28s.players)
        self.cpuPlayer = CPUPlayer(game: game)
        self.user = UserView(userSeat: .south, game: game)
    }
    
    var body: some Scene {
        WindowGroup {
            PlayingTableView()
                .environmentObject(user)
        }
    }
    
}
