//
//  CrosswordListItemView.swift
//  crosswords
//
//  Created by Rohan Narayan on 10/9/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordListItemView: View {
    var crossword: Crossword
    @ObservedObject var userSettings = UserSettings()
    
    var crosswordProgress: CGFloat {
        return getCrosswordProgress(crossword: crossword)
    }
    
    var currentTime: String {
        return toTime(Int(crossword.solvedTime))
    }

    var body: some View {
        return HStack {
            Text(self.getCrosswordListTitle(crossword: crossword))
            Spacer()
            if (crossword.solved) {
                if (userSettings.showTimer && crossword.solvedTime > 0) {
                    Text(currentTime).foregroundColor(Color.init(UIColor.systemGreen))
                }
                Image(systemName: "checkmark.circle")
                    .foregroundColor(Color(UIColor.systemGreen))
                    .font(.system(size: 20))
            }
            else if (crosswordProgress > 0) {
                if (userSettings.showTimer && crossword.solvedTime > 0) {
                    Text(currentTime).foregroundColor(Color.init(UIColor.systemOrange))
                }
                ZStack{
                    Circle()
                        .stroke(lineWidth: 5.0)
                        .opacity(0.3)
                        .foregroundColor(Color(UIColor.systemOrange))
                        .rotationEffect(Angle(degrees: 270.0))
                        .frame(width: 23, height: 23)
                    Circle()
                        .trim(from: 0.0, to: crosswordProgress)
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .rotationEffect(Angle(degrees: 270.0))
                        .frame(width: 23, height: 23)
                }
            }
        }
    }
    
    func getCrosswordListTitle(crossword: Crossword) -> String {
        let date = crossword.date!
        let formatter = DateFormatter()
        formatter.dateFormat = "EE M/d/yy"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return crossword.outletName! + " - " + formatter.string(from: date)
    }
    
    func getCrosswordProgress(crossword: Crossword) -> CGFloat {
        let fillableSquaresCount = CrosswordUtils.getFillableCellsCount(crossword.symbols!)
        let filledSquaresCount = CrosswordUtils.getFilledCellsCount(crossword.entry!)
        let retval = CGFloat(filledSquaresCount)/CGFloat(fillableSquaresCount)
        return retval
    }
}
