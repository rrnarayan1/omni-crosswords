//
//  ContentView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/19/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GameKit

struct CrosswordListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @State var refreshEnabled = true
    @State var bannerData: BannerModifier.BannerData = BannerModifier.BannerData()
    @State var openedFileUrl: URL? = nil
    @State var uploadPageActive = false
    @State var selectedCrossword: [Crossword] = []

    var userSettings = UserSettings()
    let refreshQueue = DispatchQueue(label: "refresh")
    
    @FetchRequest(entity: Crossword.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Crossword.date, ascending: false)],
                  predicate: NSPredicate(format: "isHidden == false"))
    var crosswords: FetchedResults<Crossword>

    @FetchRequest(entity: Crossword.entity(), sortDescriptors: [],
                  predicate: NSPredicate(format: "isHidden == true"))
    var hiddenCrosswords: FetchedResults<Crossword>

    init(openedFileUrl: URL? = nil) {
        self._openedFileUrl = State(initialValue: openedFileUrl)
        self._uploadPageActive = State(initialValue: openedFileUrl != nil)
    }

    var body: some View {
        NavigationStack(path: self.$selectedCrossword) {
            if (self.userSettings.user == nil && !self.userSettings.useLocalMode) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 20))
                    .onAppear(perform: {
                        self.checkUser()
                    })
            } else {
                let filteredCrosswords = self.crosswords.filter {
                    (!$0.solved || self.userSettings.showSolved)
                }
                List(filteredCrosswords, id: \.id) { crossword in
                    NavigationLink(value: crossword) {
                        CrosswordListItemView(date: crossword.date!,
                                              progressPercentage:
                                                CrosswordUtils.getCrosswordProgress(crossword),
                                              outletName: crossword.outletName!,
                                              isSolved: crossword.solved,
                                              solvedTime: Int(crossword.solvedTime),
                                              userSettings: self.userSettings)
                    }.swipeActions {
                        Button("Delete", systemImage: "trash.fill") {
                            crossword.isHidden = true
                            do {
                                try self.managedObjectContext.save()
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        .labelStyle(.iconOnly)
                        .tint(.red)
                    }
                }
                .navigationDestination(for: Crossword.self) {crossword in
                    CrosswordView(crossword: crossword, userSettings: self.userSettings)
                }
                .refreshable {
                    self.refreshCrosswords()
                 }
                .onAppear(perform: {
                    // when a file is opened and then the upload page is closed, we don't need
                    // to keep the reference to the originally opened file
                    if (!self.uploadPageActive && self.openedFileUrl != nil) {
                        self.openedFileUrl = nil
                    }
                    if (self.selectedCrossword.isEmpty) {
                        self.refreshCrosswords()
                    }
                })
                .navigationBarTitle("Crosswords")
                .navigationBarItems(trailing:
                    HStack {
                        NavigationLink(
                            destination: StatisticsView(userSettings: self.userSettings)
                        ) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 18))
                        }
                        Button {
                            self.uploadPageActive = true
                        } label: {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 18))
                        }
                        .navigationDestination(isPresented: self.$uploadPageActive) {
                            UploadPuzzleView(userSettings: self.userSettings,
                                             openedFileUrl: self.openedFileUrl)
                        }

                        NavigationLink(
                            destination: SettingsView(userSettings: self.userSettings)
                        ) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                        }
                        Button(action: {
                            self.refreshCrosswords()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18, weight: Font.Weight.bold))
                                .foregroundColor(self.refreshEnabled ? Color(UIColor.systemBlue) : Color(UIColor.systemGray))
                        }.disabled(!self.refreshEnabled)
                    }
                )
            }
        }
        .banner(data: self.$bannerData, userSettings: self.userSettings)
    }

    func checkUser() -> Void {
        if (Auth.auth().currentUser == nil) {
            Auth.auth().signInAnonymously {(authResult, error) in
                if (error == nil) {
                    self.userSettings.user = authResult?.user
                }
            }
        }
    }
    
    func refreshCrosswords() -> Void {
        if (self.userSettings.shouldTryGameCenterLogin) {
            let localPlayer = GKLocalPlayer.local
            GKLocalPlayer.local.authenticateHandler = { vc, error in
                guard error == nil else {
                    print(error?.localizedDescription ?? "")
                    self.userSettings.shouldTryGameCenterLogin = false
                    return
                }
                self.userSettings.gameCenterPlayer = localPlayer
            }
        }
        self.refreshEnabled = false

        self.refreshQueue.async() {
            if (self.userSettings.useLocalMode) {
                if (self.crosswords.isEmpty) {
                    let crossword = Crossword(context: self.managedObjectContext)
                    DataUtils.buildSampleCrossword(crossword: crossword,
                                                   resourceName: "sampleData")
                    do {
                        try self.managedObjectContext.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                self.refreshEnabled = true
                return
            }

            if (self.userSettings.user == nil) {
                self.checkUser()
            }

            // UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastRefreshTime")

            let lastDate: Date
            if self.crosswords.count == 0 {
                // pull for the last 7 days
                lastDate = Date.init(timeInterval: -604800, since: Date())
            } else {
                // crosswords are sorted by date desc, so pull the first one
                lastDate = self.crosswords[0].date!
            }

            let shownCrosswordIds: Array<String> = self.crosswords.map {$0.id!}
            var allCrosswords: Array<Crossword> = Array(self.crosswords)
            allCrosswords.append(contentsOf: self.hiddenCrosswords)
            let allCrosswordIds: Array<String> = allCrosswords.map {$0.id!}

            let db = Firestore.firestore()
            let docRef = db.collection("crosswords")
                .whereField("date", isGreaterThanOrEqualTo: lastDate)
                .whereField("crossword_outlet_name", in: self.userSettings.subscriptions)

            let lastAlertId = self.userSettings.lastAlertId
            let alertDocRef = db.collection("alerts")
                .whereField("id", isGreaterThan: lastAlertId)
                .order(by: "id", descending: true)

            let overwrittenCrosswords = db.collection("crosswords")
                .whereField("version", isGreaterThan: 0)
            
            alertDocRef.getDocuments {(querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    if (querySnapshot!.documents.count > 0) {
                        let document = querySnapshot!.documents[0]
                        self.bannerData.title = document.get("title") as! String
                        self.bannerData.detail = document.get("message") as! String
                        self.bannerData.bannerId = document.get("id") as! Int
                    }
                }
            }
            
            overwrittenCrosswords.getDocuments {(querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    for document in querySnapshot!.documents {
                        // if we aren't showing it, it doesn't need to be overwritten
                        if (!shownCrosswordIds.contains(document.documentID)) {
                            continue
                        }
                        let crossword = self.crosswords.first(where: {
                            $0.id == document.documentID && ($0.versionId < document.get("version") as! Int16)
                        })
                        if (crossword == nil) {
                            continue
                        }
                        DataUtils.jsonToCrossword(crossword: crossword!, data: document)
                        do {
                            try self.managedObjectContext.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }

            docRef.getDocuments {(querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    for document in querySnapshot!.documents {
                        // if it's hidden, then we don't need to save it
                        if (allCrosswordIds.contains(document.documentID)) {
                            continue
                        }
                        let crossword = Crossword(context: self.managedObjectContext)
                        // Cause duplicate crosswords
//                        let crossword1 = Crossword(context: self.managedObjectContext)
//                        jsonToCrossword(crossword: crossword1, data: document)
                        do {
                            DataUtils.jsonToCrossword(crossword: crossword, data: document)
                            try self.managedObjectContext.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                self.checkForDeletions(allCrosswords: allCrosswords)
                self.syncSavedGames()
                self.refreshEnabled = true
            }
        }
    }

    func getDaysAgoToDelete() -> Int {
        let days = self.userSettings.daysToWaitBeforeDeleting
        if (days == "Never") {
            return -1
        } else {
            return Int(days)!
        }
    }

    func checkForDeletions(allCrosswords: Array<Crossword>) -> Void {
        let daysAgoToDelete = self.getDaysAgoToDelete()
        if (daysAgoToDelete == -1) {
            return
        }
        let timeToGoBack: Double = Double(-1 * daysAgoToDelete * 86400)
        let lastDate = Date.init(timeInterval: timeToGoBack, since: Date())

        for crossword in allCrosswords {
            // deletes old crosswords
            if (crossword.date == nil || crossword.date! < lastDate) {
                self.deleteGame(crossword: crossword)
            }
            // deletes unsolved non-custom upload crosswords that aren't subscribed to anymore
            else if (!self.userSettings.subscriptions.contains(crossword.outletName!)
                     && !crossword.solved
                     && !(crossword.outletName! == "Custom" || crossword.isCustomUpload)) {
                self.deleteGame(crossword: crossword)
            }
            // Commented out - this deletes the most recent day's crossword
//            if crossword.date! > Date.init(timeInterval: -86400*2, since: Date()) {
//                deleteGame(crossword: crossword)
//            }
        }
    }
    
    func syncSavedGames() -> Void {
        if (self.userSettings.shouldTryGameCenterLogin && self.userSettings.gameCenterPlayer != nil) {
            self.userSettings.gameCenterPlayer?.fetchSavedGames(completionHandler: {(games, error) in
                if let error = error {
                    print("Error getting game center saved games: \(error)")
                    return
                } else if games == nil {
                    return
                }
                for game in games! {
                    game.loadData(completionHandler: {(gameData, error) in
                        if let error = error {
                            print("Error getting gameData from game center saved game: \(error)")
                            return
                        } else if (gameData == nil) {
                            return
                        }
                        
                        let entryString: String = String(data: gameData!, encoding: .utf8)!
                        let gcEntry: Array<String> = entryString.components(separatedBy: ",")
                        let savedCrossword = self.crosswords.first(where: {xw in xw.id == game.name})
                        if (savedCrossword != nil && savedCrossword?.solved == false
                            && CrosswordUtils.getFilledCellsCount((savedCrossword?.entry)!)
                            < CrosswordUtils.getFilledCellsCount(gcEntry)) {
                            // overwrite if: current crossword is not already solved and
                            // if progress would increase on the crossword
                            savedCrossword?.entry = gcEntry
                            if (gcEntry == savedCrossword?.solution) {
                                savedCrossword?.solved = true
                            } else {
                                savedCrossword?.solved = false
                            }
                        }
                    })
                }
            })
        }
    }
    
    func deleteGame(crossword: Crossword) -> Void {
        self.managedObjectContext.delete(crossword)
        
        if (self.userSettings.gameCenterPlayer != nil) {
            self.userSettings.gameCenterPlayer?.deleteSavedGames(withName: crossword.id!,
                                                                 completionHandler: {error in
                if let error = error {
                    print("Error deleting game from game center saved game: \(error)")
                    return
                }
            })
        }
        
        do {
            try self.managedObjectContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}
