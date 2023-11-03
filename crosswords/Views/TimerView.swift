//
//  TimerView.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/2/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct TimerView: View {
    
    @EnvironmentObject var timerWrapper : TimerWrapper
    var isSolved: Bool
    var solvedTime: Int?
    
    var body: some View {
        var text: Text
        if (isSolved) {
            text = Text(toTime(self.solvedTime!))
        } else {
            text = Text(toTime(self.timerWrapper.count))
        }
        return text
            .frame(width: UIScreen.screenWidth-10, height: 10, alignment: .trailing)
            .onAppear(perform: {
                if (!self.isSolved) {
                    self.timerWrapper.start(Int(self.solvedTime ?? 0))
                } else {
                    self.timerWrapper.stop()
                }
            })
    }
}

func toTime(_ currentTimeInSeconds: Int) -> String {
    let timeInSeconds = currentTimeInSeconds
    let numMin = timeInSeconds / 60
    let numSec = timeInSeconds % 60
    
    let secString: String = numSec < 10 ? "0"+String(numSec) : String(numSec)
    return String(numMin) + ":" + secString
}
