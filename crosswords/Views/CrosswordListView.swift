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

struct CrosswordListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(entity: Crossword.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Crossword.date, ascending: false)])
    
    var crosswords: FetchedResults<Crossword>
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    let lastDate: Date
                    if self.crosswords.count == 0 {
                        // 1 week ago
                        lastDate = Date.init(timeInterval: -604800, since: Date())
                    } else {
                        print(self.crosswords[0])
                        lastDate = self.crosswords[0].date!
                    }
                    
                    let db = Firestore.firestore()
                    let docRef = db.collection("crosswords").whereField("date", isGreaterThan: lastDate)
                    
                    docRef.getDocuments {(querySnapshot, error) in
                        if let error = error {
                            print("Error getting documents: \(error)")
                        } else {
                            for document in querySnapshot!.documents {
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
                }) {
                    Text("Add Crossword")
                }
                
                List(self.crosswords, id: \.id) { crossword in
                    NavigationLink(
                        destination: CrosswordView(crossword: crossword)
                            .environment(\.managedObjectContext, self.managedObjectContext)
                    ) {
                        Text(crossword.id!)
                    }
                }
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
