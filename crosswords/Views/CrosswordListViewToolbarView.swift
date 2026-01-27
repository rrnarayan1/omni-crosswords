//
//  CrosswordListToolbarView.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/26/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//
import SwiftUI

struct CrosswordListViewToolbarView: View {
    @ObservedObject var userSettings: UserSettings

    var refreshAction: () -> Void
    var refreshEnabled: Bool

    var body: some View {
        HStack {
            NavigationLink(
                destination: StatisticsView(userSettings: self.userSettings)
            ) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: Constants.crosswordListViewToolbarButtonSize))
            }

            NavigationLink(
                destination: UploadPuzzleView(userSettings: self.userSettings)
            ) {
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: Constants.crosswordListViewToolbarButtonSize))
            }

            NavigationLink(
                destination: SettingsView(userSettings: self.userSettings)
            ) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: Constants.crosswordListViewToolbarButtonSize))
            }

            Button(action: {
                self.refreshAction()
            }) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: Constants.crosswordListViewToolbarButtonSize, weight: .bold))
            }.disabled(!self.refreshEnabled)
        }
    }
}
