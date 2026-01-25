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
    var showSolution: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Toggle(isOn: self.$errorTracking) {
                    Text("Error Tracking")
                }
                .disabled(!self.isSolutionAvailable)
                .frame(width: 200)
                
                if (!self.isSolved) {
                    Button(action: {
                        self.showSolution()
                        self.dismiss()
                    }) {
                        Text("Show Solution")
                    }
                    .padding()
                    .buttonStyle(.bordered)
                    .disabled(!self.isSolutionAvailable)
                    .frame(width: 200)
                }
                
                if (!self.isSolutionAvailable) {
                    Text("""
                         Error Tracking and Show Solution are disabled because the solution
                         is not available
                    """)
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
