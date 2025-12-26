//
//  CrosswordToolbarView.swift
//  crosswords
//
//  Created by Rohan Narayan on 9/18/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

let crosswordToolbarButtonSize = 16.0

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
    
    static func == (lhs: CrosswordTrailingToolbarView, rhs: CrosswordTrailingToolbarView) -> Bool {
        // no need to refresh this view
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
            NavigationLink(
                destination: CrosswordSettingsView(title: title, author: author, notes: notes, copyright: copyright, isSolved: isSolved, isSolutionAvailable: isSolutionAvailable, errorTracking: self.isErrorTrackingEnabled, showSolution: showSolution),
                label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Color(UIColor.systemBlue))
                }
            ).simultaneousGesture(TapGesture().onEnded{
                showSettings()
            })
            .font(.system(size: crosswordToolbarButtonSize))

            Button(action: {self.showShareSheet = true}) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Color(UIColor.systemBlue))
            }.sheet(isPresented: self.$showShareSheet,
                onDismiss: {self.showShareSheet = false},
                content: {
                ActivityView(activityItems: shareSheet(isSolved: isSolved, outletName: outletName))
                }
            )
            .font(.system(size: crosswordToolbarButtonSize))
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
            goBack()
        }) {
            Image(systemName: "chevron.left")
        }.padding(0).font(.system(size: crosswordToolbarButtonSize))
    }
}

extension ToolbarContent {

    @ToolbarContentBuilder
    func hideSharedBackgroundIfAvailable() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
