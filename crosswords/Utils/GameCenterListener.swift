//
//  GameCenterListener.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/9/22.
//  Copyright © 2022 Rohan Narayan. All rights reserved.
//

import Foundation
import GameKit
import SwiftUI

final class GameCenterListener : NSObject,  GKLocalPlayerListener {
    func player(_ player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) {
        let latestGame: GKSavedGame? = savedGames.max {game1, game2 in game1.modificationDate! < game2.modificationDate!}
        latestGame?.loadData(completionHandler: {(gameData, error) in
            if let error = error {
                print("Error getting gameData from game center saved game: \(error)")
                return
            } else if (gameData == nil) {
                return
            }
            GKLocalPlayer.local.resolveConflictingSavedGames(savedGames, with: gameData!, completionHandler: {(savedGames, error) in return})
        })
    }
}
