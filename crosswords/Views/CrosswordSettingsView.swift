//
//  SheetViews.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/30/22.
//  Copyright © 2022 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordSettingsView: View {
    let title: String
    let author: String
    let notes: String
    let copyright: String
    let isSolved: Bool
    let isSolutionAvailable: Bool
    
    @Binding var errorTracking: Bool
    var showSolution: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Toggle(isOn: $errorTracking) {
                    Text("Error Tracking")
                }
                .disabled(!isSolutionAvailable)
                .frame(width: 200)
                
                if (!isSolved) {
                    Button(action: {showSolution()}) {
                        Text("Show Solution")
                    }
                    .disabled(!isSolutionAvailable)
                    .frame(width: 200)
                }
                
                if (!isSolutionAvailable) {
                    Text("Error Tracking and Show Solution are Disabled because the solution is not available")
                }
            }
            .padding([.bottom], 30)
            Text("Title: "+title)
            Text("Author: "+author)
            if (notes != "") {
                Text("Notes: "+notes)
            }
            Text(copyright)
            
            Spacer()
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 400))
        .navigationBarTitle("Crossword Settings")
        .padding([.top], 15)
    }
}

func shareSheet(isSolved: Bool, outletName: String) -> [Any] {
    var shareMessage: String
    if (isSolved) {
        shareMessage = "I solved the " + outletName + " crossword"
        shareMessage += ". Download OmniCrosswords and have fun with me!"
    } else {
        shareMessage = "I'm in the middle of solving the " + outletName + " crossword"
        shareMessage += ". Download OmniCrosswords and help me out!"
    }
    let items: [Any] = [shareMessage, URL(string: "https://apps.apple.com/us/app/omni-crosswords/id1530129670")!]
    return items
}
