//
//  ContentView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/19/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import FirebaseFirestore

struct CrosswordListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @State var refreshEnabled = true
    @State var bannerData: BannerData = BannerData()
    @State var openedFileUrl: URL? = nil
    @State var uploadPageActive = false
    @State var selectedCrossword: [Crossword] = []

    var userSettings = UserSettings()
    let refreshQueue = DispatchQueue(label: "refresh")
    
    @FetchRequest(entity: Crossword.entity(),
                  sortDescriptors: [
                    NSSortDescriptor(keyPath: \Crossword.date, ascending: false),
                    NSSortDescriptor(keyPath: \Crossword.outletName, ascending: true)
                  ],
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
                ProgressView()
                    .onAppear(perform: {
                        FirebaseUtils.checkFirebaseUser(userSettings: self.userSettings)
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
                .navigationDestination(isPresented: self.$uploadPageActive) {
                    UploadPuzzleView(userSettings: self.userSettings,
                                     openedFileUrl: self.openedFileUrl)
                }
                .refreshable {
                    self.refreshCrosswords()
                 }
                .onAppear(perform: {
                    if (self.selectedCrossword.isEmpty) {
                        self.refreshCrosswords()
                    }
                })
                .navigationBarTitle("Crosswords")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CrosswordListViewToolbarView(userSettings: self.userSettings,
                                                 refreshAction: self.refreshCrosswords,
                                                 refreshEnabled: self.refreshEnabled
                        )
                    }
                }
            }
        }
        .banner(data: self.$bannerData, userSettings: self.userSettings)
    }
    
    func refreshCrosswords() -> Void {
        if (!self.refreshEnabled) {
            return
        }

        let lastRefreshTime: Date = Date(timeIntervalSince1970: self.userSettings.lastRefreshTime)

        if (!Date().haveMinutesElapsed(timeInMinutes: 5, pastDate: lastRefreshTime)) {
            return
        }
        self.refreshEnabled = false
        self.userSettings.lastRefreshTime = Date().timeIntervalSince1970

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
                FirebaseUtils.checkFirebaseUser(userSettings: self.userSettings)
            }
            GameCenterUtils.maybeAuthenticate(userSettings: self.userSettings)

            let lastDate: Date
            if (self.crosswords.count == 0) {
                // pull for the last 7 days
                lastDate = Date().subtractWeeks(1)
            } else {
                // crosswords are sorted by date desc, so pull the first one
                lastDate = self.crosswords[0].date!
            }

            let shownCrosswordIds: Array<String> = self.crosswords.map {$0.id!}
            var allCrosswords: Array<Crossword> = Array(self.crosswords)
            allCrosswords.append(contentsOf: self.hiddenCrosswords)

            let lastAlertId = self.userSettings.lastAlertId

            FirebaseUtils.getNewAlerts(lastAlertId: lastAlertId, handler: FirebaseHandler(data: lastAlertId,
                                                        documentHandler: self.newAlertHandler,
                                                        completionHandler: nil))
            FirebaseUtils.getNewOverwrites(handler: FirebaseHandler(data: shownCrosswordIds,
                                                                    documentHandler:
                                                                        self.overwrittenCrosswordHandler,
                                                                    completionHandler: nil))
            FirebaseUtils.getNewCrosswords(lastDate: lastDate, subscriptions: self.userSettings.subscriptions,
                                           handler: FirebaseHandler(data: allCrosswords,
                                                                documentHandler: self.newCrosswordHandler,
                                                                completionHandler:
                                                                    self.newCrosswordFetchCompletionHandler))
        }
    }

    func newCrosswordHandler(document: QueryDocumentSnapshot, allCrosswords: Array<Crossword>) -> Void {
        let allCrosswordIds = allCrosswords.map {$0.id}
        if (allCrosswordIds.contains(document.documentID)) {
            return
        }
        let crossword = Crossword(context: self.managedObjectContext)
        // Cause duplicate crosswords
//         let crossword1 = Crossword(context: self.managedObjectContext)
//         jsonToCrossword(crossword: crossword1, data: document)
        do {
            DataUtils.jsonToCrossword(crossword: crossword, data: document)
            try self.managedObjectContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    func newAlertHandler(document: QueryDocumentSnapshot, _: Int) -> Void {
        self.bannerData.title = document.get("title") as! String
        self.bannerData.detail = document.get("message") as! String
        self.bannerData.bannerId = document.get("id") as! Int
    }

    func overwrittenCrosswordHandler(document: QueryDocumentSnapshot, shownCrosswordIds: Array<String>) {
        // if it's not shown, don't need to change it
        if (!shownCrosswordIds.contains(document.documentID)) {
            return
        }

        let crosswordToOverwrite = self.crosswords.first(where: {
            $0.id == document.documentID && ($0.versionId < document.get("version") as! Int16)
        })

        if (crosswordToOverwrite == nil) {
            return
        }

        DataUtils.jsonToCrossword(crossword: crosswordToOverwrite!, data: document)
        do {
            try self.managedObjectContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    func newCrosswordFetchCompletionHandler(allCrosswords: Array<Crossword>) -> Void {
        self.checkForDeletions(allCrosswords: allCrosswords)
        GameCenterUtils.maybeSyncSavedGames(userSettings: self.userSettings,
                                            crosswords: allCrosswords)
        self.refreshEnabled = true
    }

    func checkForDeletions(allCrosswords: Array<Crossword>) -> Void {
        let daysAgoToDelete = self.userSettings.getDaysAgoToDelete()
        if (daysAgoToDelete == -1) {
            return
        }
        let deleteBeforeDate = Date().subtractDays(daysAgoToDelete)

        for crossword in allCrosswords {
            // deletes old crosswords
            if (crossword.date == nil || crossword.date! < deleteBeforeDate) {
                self.deleteGame(crossword: crossword)
            }
            // deletes unsolved non-custom upload crosswords that aren't subscribed to anymore
            else if (!self.userSettings.subscriptions.contains(crossword.outletName!)
                     && !(crossword.outletName! == "Custom" || crossword.isCustomUpload)
                     && !crossword.solved) {
                self.deleteGame(crossword: crossword)
            }
            // Commented out - this deletes the most recent day's crossword
//            if crossword.date! > Date.init(timeInterval: -86400*2, since: Date()) {
//                deleteGame(crossword: crossword)
//            }
        }
    }
    
    func deleteGame(crossword: Crossword) -> Void {
        self.managedObjectContext.delete(crossword)
        GameCenterUtils.maybeDeleteGame(userSettings: self.userSettings, crosswordId: crossword.id!)

        do {
            try self.managedObjectContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}
