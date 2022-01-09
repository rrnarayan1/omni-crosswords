//
//  ContentView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/19/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift
import FontAwesome_swift
import GameKit

struct CrosswordListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var refreshEnabled = false
    @State var openCrossword: Crossword? = nil
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
    
    var body: some View {
        NavigationView {
            if (userSettings.user == nil) {
                Image(uiImage: UIImage.fontAwesomeIcon(name: .spinner, style: .solid, textColor: .systemGray, size: CGSize.init(width: 30, height: 30)))
                .onAppear(perform: {
                    self.checkUser()
                })
            } else {
            List(self.crosswords.filter { !$0.solved || self.showSolvedPuzzles || self.openCrossword == $0 }, id: \.id) { crossword in
                NavigationLink(
                    destination: CrosswordView(crossword: crossword)
                        .environment(\.managedObjectContext, self.managedObjectContext),
                    tag: crossword,
                    selection: self.$openCrossword
                ) {
                    CrosswordListItemView(crossword: crossword, openCrossword: self.openCrossword)
                }
            }.onAppear(perform: {
                self.refreshCrosswords()
            })
            .navigationBarTitle("Crosswords")
            .navigationBarItems(trailing:
                HStack {
                    NavigationLink(
                        destination: SettingsView()
                    ) {
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .cog, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize.init(width: 30, height: 30)))
                    }
                    Button(action: {
                        self.refreshCrosswords()
                    }) {
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .sync, style: FontAwesomeStyle.solid, textColor: self.refreshEnabled ? UIColor.systemBlue : UIColor.systemGray, size: CGSize.init(width: 30, height: 30)))
                    }.disabled(!self.refreshEnabled)
                }
            )
        }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
            let lastDate: Date
            if self.crosswords.count == 0 {
                lastDate = Date.init(timeInterval: -604800, since: Date())
            } else {
                lastDate = self.crosswords[0].date!
            }
            
            let db = Firestore.firestore()
            let docRef = db.collection("crosswords").whereField("date", isGreaterThanOrEqualTo: lastDate).whereField("crossword_outlet_name", in: subscriptions)
            
            let crosswordIds: Array<String> = crosswords.map { (crossword) -> String in
                crossword.id!
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
                        jsonToCrossword(crossword: crossword, data: document)
                        do {
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
            if crossword.date! < lastDate {
                deleteGame(crossword: crossword)
            } else if !self.subscriptions.contains(crossword.outletName!) && !crossword.solved {
                deleteGame(crossword: crossword)
            }
// Commented out - this deletes the most recent day's crossword
//            if crossword.date! > Date.init(timeInterval: -86400*2, since: Date()) {
//                deleteGame(crossword: crossword)
//            }
            
        }
    }
    
    func syncSavedGames() -> Void {
        if (self.userSettings.gameCenterPlayer != nil && self.openCrossword == nil) {
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
                        let savedEntry: Array<String> = entryString.components(separatedBy: ",")
                        let savedCrossword = self.crosswords.first(where: {xw in xw.id == game.name})
                        if (savedCrossword != nil) {
                            savedCrossword?.entry = savedEntry
                            if (savedEntry == savedCrossword?.solution) {
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
            self.userSettings.gameCenterPlayer?.deleteSavedGames(withName: crossword.id!, completionHandler: {error in
                if let error = error {
                    print("Error deleting gamerop from game center saved game: \(error)")
                    return
                }
            })
        }
    }
}

struct CrosswordListItemView: View {
    var crossword: Crossword
    @State var openCrossword: Crossword?
    @ObservedObject var userSettings = UserSettings()
    
    var crosswordProgress: CGFloat {
        if (openCrossword != nil && crossword.id == openCrossword!.id) {
            return getCrosswordProgress(crossword: openCrossword!)
        } else {
            return getCrosswordProgress(crossword: crossword)
        }
        
    }
    
    var currentTime: String {
        return toTime(Int(crossword.solvedTime))
    }

    var body: some View {
        HStack {
            Text(self.getCrosswordListTitle(crossword: crossword))
            Spacer()
            if (crossword.solved) {
                if (userSettings.showTimer && crossword.solvedTime > 0) {
                    Text(currentTime).foregroundColor(Color.init(UIColor.systemGreen))
                }
                Image(uiImage: UIImage.fontAwesomeIcon(name: .checkCircle, style: FontAwesomeStyle.regular, textColor: UIColor.systemGreen, size: CGSize.init(width: 30, height: 30)))
            }
            else if (crosswordProgress > 0) {
                if (userSettings.showTimer && crossword.solvedTime > 0) {
                    Text(currentTime).foregroundColor(Color.init(UIColor.systemOrange))
                }
                ZStack{
                    Circle()
                        .stroke(lineWidth: 5.0)
                        .opacity(0.3)
                        .foregroundColor(Color(UIColor.systemOrange))
                        .rotationEffect(Angle(degrees: 270.0))
                        .frame(width: 30, height: 30)
                    Circle()
                        .trim(from: 0.0, to: crosswordProgress)
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .rotationEffect(Angle(degrees: 270.0))
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
    
    func getCrosswordListTitle(crossword: Crossword) -> String {
        let date = crossword.date!
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateStyle = .short
        return crossword.outletName! + " - " + formatter.string(from: date)
    }
    
    func getCrosswordProgress(crossword: Crossword) -> CGFloat {
        let emptySquares = (crossword.symbols?.filter({ (symbol) -> Bool in
            symbol != -1
        }).count)
        let filledSquares = crossword.entry?.filter({ (entry) -> Bool in
            entry != "." && !entry.isEmpty
        }).count
        let retval = CGFloat(filledSquares!)/CGFloat(emptySquares!)
        return retval
    }
}
