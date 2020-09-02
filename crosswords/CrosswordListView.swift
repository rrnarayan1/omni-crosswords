//
//  ContentView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/19/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
struct CrosswordListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(entity: Crossword.entity(), sortDescriptors: [])
    
    var crosswords: FetchedResults<Crossword>
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    let crossword = Crossword(context: self.managedObjectContext)
                    crossword.length = 5
                    crossword.height = 5
                    crossword.id = 1
                    crossword.entry = Array(repeating: Array(repeating: "", count: 5), count: 5)
                    do {
                        try self.managedObjectContext.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                }) {
                    Text("Add Crossword")
                }
                List(self.crosswords, id: \.id) { crossword in
                    NavigationLink(
                        destination: CrosswordView(crossword: crossword)
                            .environment(\.managedObjectContext, self.managedObjectContext)
                    ) {
                        Text(String(crossword.id))
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
