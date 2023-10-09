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
    
    let isErrorTrackingEnabled: Binding<Bool>
    let showSolution: () -> Void
    let showSettings: () -> Void
    @State var showShareSheet: Bool = false
    
    static func == (lhs: CrosswordTrailingToolbarView, rhs: CrosswordTrailingToolbarView) -> Bool {
        // no need to refresh this view
        return true
    }
    
    var body: some View {
        HStack {
            NavigationLink(
                destination: CrosswordSettingsView(title: title, author: author, notes: notes, copyright: copyright, isSolved: isSolved, errorTracking: self.isErrorTrackingEnabled, showSolution: showSolution),
                label: {Image(systemName: "slider.horizontal.3")
                    .foregroundColor(Color(UIColor.systemBlue))
                    .font(.system(size: 18))}
            ).simultaneousGesture(TapGesture().onEnded{
                showSettings()
            })

            if #available(iOS 15, *) {
                Button(action: {self.showShareSheet = true}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color(UIColor.systemBlue))
                        .font(.system(size: 18))
                }.sheet(isPresented: self.$showShareSheet,
                    onDismiss: {self.showShareSheet = false},
                    content: {
                    ActivityView(activityItems: shareSheet(isSolved: isSolved, outletName: outletName))
                    }
                )
            }
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
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
                    .frame(alignment: .leading)
            }
        }
    }
}
