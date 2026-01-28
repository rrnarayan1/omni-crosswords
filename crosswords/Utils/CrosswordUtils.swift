//
//  CrosswordUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/3/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI
import CoreData

struct CrosswordUtils {

    static func getCrosswordProgress(_ crossword: Crossword) -> CGFloat {
        let fillableSquaresCount = CrosswordUtils.getFillableCellsCount(crossword.entry!)
        let filledSquaresCount = CrosswordUtils.getFilledCellsCount(crossword.entry!)
        return CGFloat(filledSquaresCount)/CGFloat(fillableSquaresCount)
    }

    static func getFilledCellsCount(_ crosswordEntry: Array<String>) -> Int {
        return crosswordEntry.filter({ (entry) -> Bool in
            entry != "." && !entry.isEmpty
        }).count
    }

    static func getFillableCellsCount(_ symbols: Array<String>) -> Int {
        return symbols.filter({ (entry) -> Bool in
            entry != "."
        }).count
    }

    static func isSolutionAvailable(crossword: Crossword) -> Bool {
        if (crossword.solution == nil || crossword.solution!.isEmpty) {
            return false
        }
        let solutionSet = Set(crossword.solution!)
        return solutionSet != Set(["X","."])
    }

    static func solveCell(tag: Int, crossword: Crossword, userSettings: UserSettings,
                          focusedTag: Binding<Int>, becomeFirstResponder: Binding<Bool>,
                          goingAcross: Binding<Bool>, isHighlighted: Binding<Array<Int>>,
                          timerWrapper: TimerWrapper?, managedObjectContext: NSManagedObjectContext)
    -> Void {
        crossword.entry![tag] = crossword.solution![tag]
        crossword.helpTracking![tag] = true
        if (crossword.entry == crossword.solution) {
            CrosswordUtils.solutionHandler(crossword: crossword, shouldAddStatistics: true,
                                           userSettings: userSettings, focusedTag: focusedTag,
                                           becomeFirstResponder: becomeFirstResponder,
                                           isHighlighted: isHighlighted, timerWrapper: timerWrapper,
                                           managedObjectContext: managedObjectContext)
            return
        } else if (focusedTag.wrappedValue == tag) {
            ChangeFocusUtils.moveFocusToNextFieldAndCheck(focusedTag: focusedTag,
                                                          crossword: crossword,
                                                          userSettings: userSettings,
                                                          goingAcross: goingAcross,
                                                          isHighlighted: isHighlighted)
        } else {
            ChangeFocusUtils.changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross,
                                         focusedTag: focusedTag, isHighlighted: isHighlighted)
        }
        CrosswordUtils.saveGame(crossword: crossword, userSettings: userSettings)
    }

    static func solutionHandler(crossword: Crossword, shouldAddStatistics: Bool = true,
                                shouldCheckSolution: Bool = true, userSettings: UserSettings,
                                focusedTag: Binding<Int>, becomeFirstResponder: Binding<Bool>,
                                isHighlighted: Binding<Array<Int>>, timerWrapper: TimerWrapper?,
                                managedObjectContext: NSManagedObjectContext)
    -> Void {
        if (shouldCheckSolution && crossword.entry != crossword.solution) {
            // this function should not have been called, the crossword isn't solved
            return
        }
        crossword.solved = true
        timerWrapper?.stop()
        if (shouldAddStatistics) {
            let solvedCrossword = SolvedCrossword(context: managedObjectContext)
            DataUtils.buildSolvedCrossword(solvedCrossword: solvedCrossword, crossword: crossword)
        }
        focusedTag.wrappedValue = -1
        isHighlighted.wrappedValue = Array<Int>()
        becomeFirstResponder.wrappedValue = false
        CrosswordUtils.saveGame(crossword: crossword, userSettings: userSettings)
    }

    static func saveGame(crossword: Crossword, userSettings: UserSettings) -> Void {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        GameCenterUtils.maybeSaveGame(userSettings: userSettings, crosswordId: crossword.id!,
                                      crosswordEntry: crossword.entry!)
    }

    static func getTagFromRowAndColNumbers(rowNum: Int, colNum: Int, crossword: Crossword) -> Int {
        return rowNum * Int(crossword.length) + colNum
    }

    static func getRowNumberFromTag(tag: Int, crossword: Crossword) -> Int {
        return tag / Int(crossword.length)
    }

    static func getPreviousTag(tag: Int, goingAcross: Bool, crossword: Crossword) -> Int {
        if (goingAcross) {
            return tag - 1
        } else {
            return tag - Int(crossword.length)
        }
    }

    static func getNextTag(tag: Int, goingAcross: Bool, crossword: Crossword) -> Int {
        if (goingAcross) {
            return tag + 1
        } else {
            return tag + Int(crossword.length)
        }
    }

    static func getClueID(tag: Int, crossword: Crossword, goingAcross: Bool) -> String {
        if (tag < 0 || tag > crossword.tagToCluesMap!.count || crossword.tagToCluesMap![tag].isEmpty) {
            return ""
        }
        let directionalLetter: String = goingAcross ? "A" : "D"
        return crossword.tagToCluesMap![tag][directionalLetter]!
    }

    static func getClue(focusedTag: Int, crossword: Crossword, goingAcross: Bool) -> String {
        let clueID = CrosswordUtils.getClueID(tag: focusedTag, crossword: crossword,
                                              goingAcross: goingAcross)
        return crossword.clues![clueID] ?? ""
    }
}
