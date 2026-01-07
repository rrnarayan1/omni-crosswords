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

    @State var refreshEnabled = false
    @State var bannerData: BannerModifier.BannerData = BannerModifier.BannerData()
    @State var openedFileUrl: URL? = nil
    @State var uploadPageActive = false

    @ObservedObject var userSettings = UserSettings()
    let refreshQueue = DispatchQueue(label: "refresh")
    
    @FetchRequest(entity: Crossword.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Crossword.date, ascending: false)])
    var crosswords: FetchedResults<Crossword>
    var showSolvedPuzzles: Bool {
        UserDefaults.standard.object(forKey: "showSolved") as? Bool ?? true
    }
    
    var subscriptions: Array<String> {
        UserDefaults.standard.object(forKey: "subscriptions") as? Array<String> ?? allSubscriptions
    }
    
    var daysAgoToDelete: Int {
        let days = UserDefaults.standard.object(forKey: "daysToWaitBeforeDeleting") as? String ?? "14"
        if (days == "Never") {
            return -1
        } else {
            return Int(days)!
        }
    }

    init() {
    }

    init(openedFileUrl: URL?) {
        self._openedFileUrl = State(initialValue: openedFileUrl)
        self._uploadPageActive = State(initialValue: openedFileUrl != nil)
    }

    var body: some View {
        NavigationStack {
            if (userSettings.user == nil && !userSettings.useLocalMode) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 20))
                    .onAppear(perform: {
                        self.checkUser()
                    })
            } else {
                let filteredCrosswords = self.crosswords.filter {
                    (!$0.solved || self.showSolvedPuzzles) && !$0.isHidden
                }
                List(filteredCrosswords, id: \.id) { crossword in
                    NavigationLink {
                        NavigationLazyView(CrosswordView(crossword: crossword))
                            .environment(\.managedObjectContext, self.managedObjectContext)
                    } label: {
                        CrosswordListItemView(
                            crossword: crossword,
                        )
                    }.swipeActions {
                        Button("Delete", systemImage: "trash.fill") {
                            crossword.isHidden = true
                        }
                        .labelStyle(.iconOnly)
                        .tint(.red)
                    }
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
                    self.refreshCrosswords()
                })
                .navigationBarTitle("Crosswords")
                .navigationBarItems(trailing:
                    HStack {
                        NavigationLink(
                            destination: StatisticsView()
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
                        NavigationLink(
                            destination: SettingsView()
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
                .navigationDestination(isPresented: self.$uploadPageActive) {
                    UploadPuzzleView(openedFileUrl: self.openedFileUrl)
                }
            }
        }
        .banner(data: self.$bannerData)
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
        
        refreshQueue.async() {
            if (userSettings.useLocalMode) {
                if (crosswords.isEmpty) {
                    let crossword = Crossword(context: self.managedObjectContext)
                    buildSampleCrossword(crossword: crossword)
                    do {
                        try self.managedObjectContext.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                self.refreshEnabled = true
                return
            }

            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastRefreshTime")

            let lastDate: Date
            if self.crosswords.count == 0 {
                // pull for the last 7 days
                lastDate = Date.init(timeInterval: -604800, since: Date())
            } else {
                // crosswords are sorted by date desc, so pull the first one
                lastDate = self.crosswords[0].date!
            }
            
            let db = Firestore.firestore()
            let docRef = db.collection("crosswords")
                .whereField("date", isGreaterThanOrEqualTo: lastDate)
                .whereField("crossword_outlet_name", in: subscriptions)
            
            
            let lastAlertId = UserDefaults.standard.integer(forKey: "lastAlertId")
            let alertDocRef = db.collection("alerts")
                .whereField("id", isGreaterThan: lastAlertId)
                .order(by: "id", descending: true)
            
            let crosswordIds: Array<String> = crosswords.map { (crossword) -> String in
                crossword.id!
            }
            
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
                        if (!crosswordIds.contains(document.documentID)) {
                            continue
                        }
                        let crossword = crosswords.first(where: {
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
                        if (crosswordIds.contains(document.documentID)) {
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
                checkForDeletions()
                syncSavedGames()
                self.refreshEnabled = true
            }
        }
    }
    
    func checkForDeletions() -> Void {
        if (daysAgoToDelete == -1) {
            return
        }
        let timeToGoBack: Double = Double(-1 * daysAgoToDelete * 86400)
        let lastDate = Date.init(timeInterval: timeToGoBack, since: Date())
        for crossword in self.crosswords {
            if (crossword.date == nil) {
                deleteGame(crossword: crossword)
            }
            // deletes old crosswords
            if crossword.date! < lastDate {
                deleteGame(crossword: crossword)
            }
            // deletes unsolved non-custom upload crosswords that aren't subscribed to anymore
            else if (!self.subscriptions.contains(crossword.outletName!) && !crossword.solved &&
                        !(crossword.outletName! == "Custom" || crossword.isCustomUpload)) {
                deleteGame(crossword: crossword)
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
                        if (savedCrossword != nil && savedCrossword?.solved == false &&
                            getFilledCellsCount((savedCrossword?.entry)!) < getFilledCellsCount(gcEntry)) {
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
    
    func hideGame(crossword: Crossword) -> Void {
        crossword.isHidden = true
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    func deleteGame(crossword: Crossword) -> Void {
        self.managedObjectContext.delete(crossword)
        
        if (self.userSettings.gameCenterPlayer != nil) {
            self.userSettings.gameCenterPlayer?.deleteSavedGames(withName: crossword.id!, completionHandler: {error in
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
