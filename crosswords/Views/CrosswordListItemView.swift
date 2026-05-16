//
//  CrosswordListItemView.swift
//  crosswords
//
//  Created by Rohan Narayan on 10/9/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordListItemView: View {
    var date: Date
    var progressPercentage: CGFloat
    var outletName: String
    var isSolved: Bool
    var solvedWithoutHelp: Bool
    var solvedTime: Int
    @ObservedObject var userSettings: UserSettings

    var body: some View {
        return HStack {
            Text(self.getCrosswordListTitle())
            Spacer()
            if (self.isSolved) {
                if (self.userSettings.showTimer && self.solvedTime > 0) {
                    Text(TimeUtils.toDisplayTime(self.solvedTime))
                        .foregroundColor(Color(self.showSolvedWithoutHelp() ? Constants.gold : UIColor.systemGreen))
                }
                if (self.showSolvedWithoutHelp()) {
                    Image(systemName: "star.circle")
                        .foregroundColor(Color(Constants.gold))
                        .font(.system(size: Constants.listIconSize))
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(Color(UIColor.systemGreen))
                        .font(.system(size: Constants.listIconSize))
                }
            }
            else if (self.progressPercentage > 0) {
                if (self.userSettings.showTimer && self.solvedTime > 0) {
                    Text(TimeUtils.toDisplayTime(self.solvedTime))
                        .foregroundColor(.orange)
                }
                ZStack{
                    Circle()
                        .stroke(lineWidth: 5.0)
                        .opacity(0.3)
                        .foregroundColor(.orange)
                        .rotationEffect(Angle(degrees: 270.0))
                        .frame(width: Constants.listIconSize, height: Constants.listIconSize)
                    Circle()
                        .trim(from: 0.0, to: self.progressPercentage)
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.orange)
                        .rotationEffect(Angle(degrees: 270.0))
                        .frame(width: Constants.listIconSize, height: Constants.listIconSize)
                }
            }
        }
    }
    
    func showSolvedWithoutHelp() -> Bool {
        return self.userSettings.showHelpIndicators && self.solvedWithoutHelp
    }

    func getCrosswordListTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE M/d/yy"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return self.outletName + " - " + formatter.string(from: self.date)
    }
}
