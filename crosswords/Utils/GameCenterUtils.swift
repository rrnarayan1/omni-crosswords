//
//  GameCenterUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/26/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//
import GameKit
import CoreData

struct GameCenterUtils {

    static func isAuthenticated() -> Bool {
        return GKLocalPlayer.local.isAuthenticated
    }

    static func maybeAuthenticate(userSettings: UserSettings) -> Void {
        if (userSettings.shouldTryGameCenterLogin && !GameCenterUtils.isAuthenticated()) {
            GKLocalPlayer.local.authenticateHandler = { vc, error in
                if (error != nil) {
                    print("Error when authenticating for GC \(error?.localizedDescription, default: "")")
                    return
                }
                GKLocalPlayer.local.register(GameCenterListener())
            }
        }
    }

    static func fetchGames(userSettings: UserSettings,
                           completionHandler: @escaping (Array<GKSavedGame>) -> Void = {_ in },
                           errorHandler: @escaping (Error) -> Void = {_ in }) -> Void {
        if (!userSettings.shouldTryGameCenterLogin) {
            return
        } else if (!GameCenterUtils.isAuthenticated()) {
            print("Trying to fetch GC games but user is not authenticated")
            return
        }
        GKLocalPlayer.local.fetchSavedGames(completionHandler: {(games, error) in
            print("Inside fetch games completion handler")
            print(games ?? "")
            if (error != nil || games == nil){
                return errorHandler(error!)
            }
            return completionHandler(games!)
        })

    }

    static func maybeSyncSavedGames(userSettings: UserSettings, crosswords: Array<Crossword>) -> Void {
        if (!userSettings.shouldTryGameCenterLogin) {
            return
        } else if (!GameCenterUtils.isAuthenticated()) {
            print("Trying to sync GC games but user is not authenticated")
            return
        }
        return fetchGames(userSettings: userSettings, completionHandler: {fetchedGames in
            GameCenterUtils.syncSavedGames(crosswords: crosswords, fetchedGames: fetchedGames)
        })
    }

    private static func syncSavedGames(crosswords: Array<Crossword>, fetchedGames: Array<GKSavedGame>) {
        for game in fetchedGames {
            game.loadData(completionHandler: {(gameData, error) in
                if (error != nil || gameData == nil) {
                    print("Error getting gameData from game center saved game: \(error, default: "")")
                    return
                }

                let gcEntryString: String = String(data: gameData!, encoding: .utf8)!
                let gcEntry: Array<String> = gcEntryString.components(separatedBy: ",")
                let savedCrossword = crosswords.first(where: {$0.id == game.name})
                var shouldSave = false
                if (savedCrossword != nil && !savedCrossword!.solved
                    && !savedCrossword!.isHidden
                    && CrosswordUtils.getFilledCellsCount((savedCrossword?.entry)!)
                        < CrosswordUtils.getFilledCellsCount(gcEntry)) {
                    // overwrite if: current crossword is not already solved, not hidden, and
                    // if progress would increase on the crossword
                    shouldSave = true
                    savedCrossword?.entry = gcEntry
                    if (gcEntry == savedCrossword?.solution) {
                        savedCrossword?.solved = true
                    }
                }
                if (shouldSave) {
                    (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
                }
            })
        }
    }

    static func maybeSaveGame(userSettings: UserSettings, crosswordId: String,
                              crosswordEntry: Array<String>) -> Void {
        if (!userSettings.shouldTryGameCenterLogin) {
            return
        } else if (!GameCenterUtils.isAuthenticated()) {
            print("Trying to save GC game but user is not authenticated")
            return
        }
        let entryString: String = crosswordEntry.joined(separator: ",")

        GKLocalPlayer.local.saveGameData(
            entryString.data(using: .utf8)!,
            withName: crosswordId,
            completionHandler: {_, error in
                if (error != nil) {
                    print("Error when saving to game center: \(error, default: "")")
                }
            }
        )
    }

    static func maybeDeleteGame(userSettings: UserSettings, crosswordId: String) -> Void {
        if (!userSettings.shouldTryGameCenterLogin) {
            return
        } else if (!GameCenterUtils.isAuthenticated()) {
            print("Trying to delete GC game but user is not authenticated")
            return
        }

        GKLocalPlayer.local.deleteSavedGames(withName: crosswordId, completionHandler: {error in
            if let error = error {
                print("Error deleting game from game center saved game: \(error)")
                return
            }
        })
    }
}
