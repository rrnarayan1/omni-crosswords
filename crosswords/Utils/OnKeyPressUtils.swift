//
//  OnKeyPressUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 3/14/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct OnKeyPressUtils {

    static func onKeyPress(press: KeyPress, focusedTag: Binding<Int>, crossword: Crossword,
                           userSettings: UserSettings, goingAcross: Binding<Bool>,
                           isHighlighted: Binding<Array<Int>>) -> KeyPress.Result {
        if (press.key == .tab) {
            if (press.modifiers.contains(.shift)) {
                ChangeFocusUtils.goToPreviousClue(focusedTag: focusedTag, crossword: crossword,
                                                  userSettings: userSettings, goingAcross: goingAcross,
                                                  isHighlighted: isHighlighted)
                return .ignored
            }
            ChangeFocusUtils.goToNextClue(focusedTag: focusedTag, crossword: crossword,
                                          userSettings: userSettings, goingAcross: goingAcross,
                                          isHighlighted: isHighlighted)
        }
        return .ignored
    }
}
