//
//  CrosswordToolbarView.swift
//  crosswords
//
//  Created by Rohan Narayan on 9/18/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordTrailingToolbarView: View, Equatable {
    let title: String
    let author: String
    let notes: String
    let copyright: String
    let isSolved: Bool
    let outletName: String
    let isSolutionAvailable: Bool
    
    let isErrorTrackingEnabled: Binding<Bool>
    let showSolution: () -> Void
    let showSettings: () -> Void
    @State var showShareSheet: Bool = false
    @State var showCrosswordSettings: Bool = false

    static func == (lhs: CrosswordTrailingToolbarView, rhs: CrosswordTrailingToolbarView) -> Bool {
        // refresh the view if crossword is now solved
        if (lhs.isSolved != rhs.isSolved) {
            return false
        }
        return true
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

    var body: some View {
        HStack {
            Button {
                self.showSettings()
                DispatchQueue.main.async {
                    self.showCrosswordSettings = true
                }

            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .navigationDestination(isPresented: self.$showCrosswordSettings) {
                CrosswordSettingsView(title: self.title, author: self.author, notes: self.notes,
                                      copyright: self.copyright, isSolved: self.isSolved,
                                      isSolutionAvailable: self.isSolutionAvailable,
                                      errorTracking: self.isErrorTrackingEnabled,
                                      showSolution: self.showSolution)
            }
            .tint(Color(UIColor.label))
            .font(.system(size: Constants.crosswordToolbarButtonSize))

            Button {
                self.showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .sheet(isPresented: self.$showShareSheet,
                   onDismiss: {self.showShareSheet = false},
                   content: {ActivityView(activityItems:
                                            self.shareSheet(isSolved: isSolved, outletName: outletName))}
            )
            .tint(Color(UIColor.label))
            .font(.system(size: Constants.crosswordToolbarButtonSize))
        }
    }
}

struct CrosswordLeadingToolbarView: View, Equatable {
    let goBack: () -> Void
    
    static func == (lhs: CrosswordLeadingToolbarView, rhs: CrosswordLeadingToolbarView) -> Bool {
        // no need to refresh this view
        return true
    }
    
    var body: some View {
        Button(action: {
            self.goBack()
        }) {
            Image(systemName: "chevron.left")
        }
        .padding(0)
        .tint(Color(UIColor.label))
        .font(.system(size: Constants.crosswordToolbarButtonSize))
    }
}
