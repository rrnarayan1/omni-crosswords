//
//  CrosswordUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/3/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordUtils {
    static func getFilledCellsCount(_ crosswordEntry: Array<String>) -> Int {
        return crosswordEntry.filter({ (entry) -> Bool in
            entry != "." && !entry.isEmpty
        }).count
    }

    static func getFillableCellsCount(_ symbols: Array<Int>) -> Int {
        return symbols.filter({ (symbol) -> Bool in
            symbol != -1
        }).count
    }

    static func isSolutionAvailable(crossword: Crossword) -> Bool {
        let solutionSet = Set(crossword.solution!)
        return solutionSet != Set(["X","."])
    }

    static func solveCell(tag: Int, crossword: Crossword, focusedTag: Binding<Int>, goingAcross: Binding<Bool>, isHighlighted: Binding<Array<Int>>) -> Void {
        crossword.entry![tag] = crossword.solution![tag]
        if (crossword.entry == crossword.solution) {
            crossword.solved = true
        } else if (focusedTag.wrappedValue == tag) {
            moveFocusToNextFieldAndCheck(currentTag: tag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
        } else {
            changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
        }
    }

    static func getRowNumberFromTag(tag: Int, crossword: Crossword) -> Int {
        return tag / Int(crossword.length)
    }
}
