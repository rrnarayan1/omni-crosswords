//
//  SheetViews.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/30/22.
//  Copyright © 2022 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let author: String
    let notes: String
    let copyright: String
    let isSolved: Bool
    let isSolutionAvailable: Bool
    
    @Binding var errorTracking: Bool
    let showSolution: () -> Void
    let getProgressPercentage: () -> CGFloat
    let markAsSolved: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Toggle(isOn: self.$errorTracking) {
                    Text("Error Tracking")
                }
                .disabled(!self.isSolutionAvailable)
                .frame(width: 200)
                
                if (!self.isSolved && self.isSolutionAvailable) {
                    Button(action: {
                        self.showSolution()
                        self.dismiss()
                    }) {
                        Text("Show Solution")
                    }
                    .padding()
                    .buttonStyle(.bordered)
                    .frame(width: 200)
                }

                if (!self.isSolutionAvailable && !self.isSolved) {
                    Button(action: {
                        self.markAsSolved()
                        self.dismiss()
                    }) {
                        Text("Mark as Solved")
                    }
                    .padding()
                    .disabled(self.getProgressPercentage() != 1.0)
                    .buttonStyle(.bordered)
                    .frame(width: 200)

                    Text("Error Tracking is disabled because the solution is not available. " +
                         "Complete the puzzle to mark it as solved.")
                    .multilineTextAlignment(.center)
                }
            }
            .padding([.bottom], 30)
            Text("Title: " + self.title)
            Text("Author: " + self.author)
            if (self.notes != "") {
                Text("Notes: " + self.notes)
            }
            Text(self.copyright)

            Spacer()
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 400))
        .navigationBarTitle("Crossword Settings")
        .padding([.top], 15)
    }
}
