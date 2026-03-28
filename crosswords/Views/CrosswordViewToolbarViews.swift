//
//  CrosswordToolbarView.swift
//  crosswords
//
//  Created by Rohan Narayan on 9/18/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordViewTrailingToolbarView: View, Equatable {
    let crosswordTitle: String
    let author: String
    let notes: String
    let copyright: String
    let isSolved: Bool
    let outletName: String
    let isSolutionAvailable: Bool

    let showSettings: () -> Void
    let showSolution: () -> Void
    let getProgressPercentage: () -> CGFloat
    let getShareMessage: () -> String
    let markAsSolved: () -> Void
    let isErrorTrackingEnabled: Binding<Bool>
    let errorTrackingEnablementSideEffect: () -> Void

    @State var showShareSheet: Bool = false
    @State var showCrosswordSettings: Bool = false

    static func == (lhs: CrosswordViewTrailingToolbarView,
                    rhs: CrosswordViewTrailingToolbarView) -> Bool {
        // refresh the view if crossword is now solved
        if (lhs.isSolved != rhs.isSolved) {
            return false
        }
        return true
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
                CrosswordSettingsView(title: self.crosswordTitle, author: self.author, notes: self.notes,
                                      copyright: self.copyright, isSolved: self.isSolved,
                                      isSolutionAvailable: self.isSolutionAvailable,
                                      showSolution: self.showSolution,
                                      getProgressPercentage: self.getProgressPercentage,
                                      markAsSolved: self.markAsSolved,
                                      errorTracking: self.isErrorTrackingEnabled,
                                      errorTrackingEnablementSideEffect:
                                        self.errorTrackingEnablementSideEffect)
            }
            .tint(Color(UIColor.label))
            .font(.system(size: Constants.crosswordToolbarButtonSize))

            ShareLink(item: self.getShareMessage()) {
                Label("", systemImage: "square.and.arrow.up")
            }
            .tint(Color(UIColor.label))
            .font(.system(size: Constants.crosswordToolbarButtonSize))
        }
    }
}

struct CrosswordViewLeadingToolbarView: View, Equatable {
    let goBack: () -> Void
    
    static func == (lhs: CrosswordViewLeadingToolbarView,
                    rhs: CrosswordViewLeadingToolbarView) -> Bool {
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
