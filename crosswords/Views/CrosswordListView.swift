//
//  ContentView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/19/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift
import FontAwesome_swift

struct CrosswordListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var fetchDisabled = false
    @State var showSettings = false
    @ObservedObject var userSettings = UserSettings()
    
    @FetchRequest(entity: Crossword.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Crossword.date, ascending: false)])
    
    var crosswords: FetchedResults<Crossword>
    var showSolvedPuzzles: Bool {
        UserDefaults.standard.object(forKey: "showSolved") as? Bool ?? false
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
            List(self.crosswords.filter { !$0.solved || self.showSolvedPuzzles }, id: \.id) { crossword in
                NavigationLink(
                    destination: CrosswordView(crossword: crossword)
                        .environment(\.managedObjectContext, self.managedObjectContext)
                ) {
                    HStack {
                        Text(self.getCrosswordListTitle(crossword: crossword))
                        if (crossword.solved) {
                            Spacer()
                            Image(uiImage: UIImage.fontAwesomeIcon(name: .checkCircle, style: FontAwesomeStyle.regular, textColor: UIColor.systemGreen, size: CGSize.init(width: 30, height: 30)))
                        }
                    }
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
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .cog, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize.init(width: 30, height: 30)))
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView()
                    }
                    Button(action: {
                        self.refreshCrosswords()
                    }) {
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .sync, style: FontAwesomeStyle.solid, textColor: UIColor.systemGreen, size: CGSize.init(width: 30, height: 30)))
                    }.disabled(fetchDisabled)
                }
            )
        }
    }
    
    func refreshCrosswords() -> Void {
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
    
    func getCrosswordListTitle(crossword: Crossword) -> String {
        let date = crossword.date!
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateStyle = .short
        return crossword.outletName! + " - " + formatter.string(from: date)
    }
}

struct CrosswordListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        return CrosswordListView().environment(\.managedObjectContext, context)
    }
}
