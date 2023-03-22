//
//  SheetViews.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/30/22.
//  Copyright © 2022 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordSettingsView: View {
    var crossword: Crossword
    @Binding var errorTracking: Bool
    var showSolution: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Toggle(isOn: $errorTracking) {
                    Text("Error Tracking")
                }
                .frame(width: 200)
                
                if (!crossword.solved) {
                    Button(action: {self.showSolution()}) {
                        Text("Show Solution")
                    }
                    .frame(width: 200)
                }
            }
            .padding(30)

            Text("Title: "+self.crossword.title!)
            Text("Author: "+self.crossword.author!)
            if (self.crossword.notes! != "") {
                Text("Notes: "+self.crossword.notes!)
            }
            Text(self.crossword.copyright!)
            
            Spacer()
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 400))
        .navigationBarTitle("Crossword Settings", displayMode: .large)
        .navigationBarColor(.systemGray6)
        .padding(30)
    }
}

func shareSheet(crossword: Crossword) -> [Any] {
    var shareMessage: String
    if (crossword.solved) {
        shareMessage = "I solved the " + crossword.outletName! + " crossword in "
        shareMessage += String(toTime(Int(crossword.solvedTime)))
        shareMessage += ". Download OmniCrosswords and try to beat my time!"
    } else {
        shareMessage = "I'm in the middle of solving the " + crossword.outletName! + " crossword"
        shareMessage += ". Download OmniCrosswords and help me out!"
    }
    let items: [Any] = [shareMessage, URL(string: "https://apps.apple.com/us/app/omni-crosswords/id1530129670")!]
    return items
}
