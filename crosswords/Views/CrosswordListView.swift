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

struct CrosswordListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var fetchDisabled = false
    @State var showSettings = false
    @State var openCrossword: Crossword? = nil
    @ObservedObject var userSettings = UserSettings()
    
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
                    CrosswordListItemView(crossword: crossword, openCrossword: self.openCrossword, showSettings: self.showSettings)
                }
            }.onAppear(perform: {
                self.refreshCrosswords()
            })
            .navigationBarTitle("Crosswords")
            .navigationBarItems(trailing:
                HStack {
                    Button(action: {
                        self.showSettings.toggle()
                    }) {
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .cog, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize.init(width: 30, height: 30)))
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView()
                    }
                    Button(action: {
                        self.refreshCrosswords()
                    }) {
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .sync, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize.init(width: 30, height: 30)))
                    }.disabled(fetchDisabled)
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
        if (self.fetchDisabled) {
            return
        }
        
        self.fetchDisabled = true
        let lastDate: Date
        
        if self.crosswords.count == 0 {
            // 1 week ago
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
        }
        checkForDeletions()
        self.fetchDisabled = false
    }
    
    func checkForDeletions() -> Void {
        if (daysAgoToDelete == -1) {
            return
        }
        let timeToGoBack: Double = Double(-1 * daysAgoToDelete * 86400)
        let lastDate = Date.init(timeInterval: timeToGoBack, since: Date())
        for crossword in self.crosswords {
            if crossword.date! < lastDate {
                self.managedObjectContext.delete(crossword)
            } else if !self.subscriptions.contains(crossword.outletName!) && !crossword.solved {
                self.managedObjectContext.delete(crossword)
            }
        }
    }
}

struct CrosswordListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        return CrosswordListView().environment(\.managedObjectContext, context)
    }
}

struct CrosswordListItemView: View {
    var crossword: Crossword
    @State var openCrossword: Crossword?
    @State var showSettings: Bool
    @ObservedObject var userSettings = UserSettings()
    
    var crosswordProgress: CGFloat {
        if (openCrossword != nil && crossword.id == openCrossword!.id) {
            return getCrosswordProgress(crossword: openCrossword!)
        } else {
            return getCrosswordProgress(crossword: crossword)
        }
        
    }
    
    var currentTime: String {
        if (showSettings) {
            return " "+toTime(Int(crossword.solvedTime))
        } else {
            return toTime(Int(crossword.solvedTime))
        }
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
