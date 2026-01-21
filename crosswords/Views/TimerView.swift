//
//  TimerView.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/2/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timerWrapper: TimerWrapper
    var isSolved: Bool
    var solvedTime: Int?
    
    var body: some View {
        var text: Text
        if (self.isSolved) {
            text = Text(TimeUtils.toDisplayTime(self.solvedTime!))
        } else {
            text = Text(TimeUtils.toDisplayTime(self.timerWrapper.count))
        }
        return text
            .onAppear(perform: {
                if (!self.isSolved) {
                    self.timerWrapper.start(Int(self.solvedTime ?? 0))
                } else {
                    self.timerWrapper.stop()
                }
            })
    }
}
