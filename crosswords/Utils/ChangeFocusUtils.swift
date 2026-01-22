//
//  ChangeFocusUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/20/21.
//  Copyright © 2021 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct ChangeFocusUtils {
    /**
     Moves focus to the next applicable cell, checking forwards. Does apply checks to skip completed cells
     */
    static func moveFocusToNextFieldAndCheck(focusedTag: Binding<Int>, crossword: Crossword,
                                             goingAcross: Binding<Bool>,
                                             isHighlighted: Binding<Array<Int>>) {
        let nextTag: Int = CrosswordUtils.getNextTag(tag: focusedTag.wrappedValue,
                                                     goingAcross: goingAcross.wrappedValue,
                                                     crossword: crossword)
        ChangeFocusUtils.moveFocusToFieldAndCheck(currentTag: focusedTag.wrappedValue, tag: nextTag,
                                                  crossword: crossword, goingAcross: goingAcross,
                                                  focusedTag: focusedTag, isHighlighted: isHighlighted,
                                                  checkCluesForwards: true, checkLoopingBack: true)
    }

    /**
     Changes focus to specified tag. Does not perform any checks to skip completed cells. If the specified tag is invalid, removes all focus.
     */
    static func changeFocus(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>,
                            focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
        if (tag < 0 || tag >= crossword.symbols!.count || crossword.tagToCluesMap?[tag] == nil
            || crossword.tagToCluesMap?[tag].count == 0) {
            focusedTag.wrappedValue = -1
            isHighlighted.wrappedValue = Array<Int>()
            return
        }
        focusedTag.wrappedValue = tag
        let currentDirection = goingAcross.wrappedValue ? "A" : "D"
        if (crossword.tagToCluesMap?[tag][currentDirection] == nil) {
            // if we're going across and across clue doesn't exist, switch to going down
            goingAcross.wrappedValue = !goingAcross.wrappedValue
        }
        ChangeFocusUtils.setHighlighting(focusedTag: tag, crossword: crossword,
                                         goingAcross: goingAcross.wrappedValue,
                                         isHighlighted: isHighlighted)
    }

    /**
     Toggles the clue direction (across/down). If specified tag is invalid, does nothing.
     */
    static func toggleDirection(focusedTag: Int, crossword: Crossword, goingAcross: Binding<Bool>,
                                isHighlighted: Binding<Array<Int>>) {
        if (focusedTag < 0 || focusedTag > crossword.entry!.count
            || crossword.entry![focusedTag] == ".") {
            return
        }
        let newDirection = goingAcross.wrappedValue ? "D" : "A"
        if (crossword.tagToCluesMap?[focusedTag][newDirection] == nil) {
            // if we're going to try to go to across and across clue doesn't exist, do nothing
            return
        }
        goingAcross.wrappedValue = !goingAcross.wrappedValue
        ChangeFocusUtils.setHighlighting(focusedTag: focusedTag, crossword: crossword,
                                         goingAcross: goingAcross.wrappedValue,
                                         isHighlighted: isHighlighted)
    }

    private static func setHighlighting(focusedTag: Int, crossword: Crossword, goingAcross: Bool,
                                        isHighlighted: Binding<Array<Int>>) {
        var newHighlighted = Array<Int>()
        // newHighlighted.append(focusedTag)

        let directionalLetter: String = goingAcross ? "A" : "D"
        let clue: String = (crossword.tagToCluesMap?[focusedTag][directionalLetter])!

        let clueTags: Array<Int> = (crossword.clueToTagsMap?[clue])!
        for tag in clueTags {
            newHighlighted.append(tag)
        }
        isHighlighted.wrappedValue = newHighlighted
    }

    /**
     Goes to the first cell of the next clue, then starts to apply checks to skip completed cells, checking backwards
     */
    static func goToNextClue(focusedTag: Binding<Int>, crossword: Crossword, goingAcross: Binding<Bool>,
                             isHighlighted: Binding<Array<Int>>) {
        let nextClueId: String = ChangeFocusUtils.getNextClueID(tag: focusedTag.wrappedValue,
                                                                crossword: crossword,
                                                                goingAcross: goingAcross)
        let nextClueStartTag: Int = crossword.clueToTagsMap![nextClueId]!.min()!
        ChangeFocusUtils.moveFocusToFieldAndCheck(currentTag: focusedTag.wrappedValue,
                                                  tag: nextClueStartTag, crossword: crossword,
                                                  goingAcross: goingAcross, focusedTag: focusedTag,
                                                  isHighlighted: isHighlighted, checkCluesForwards: true,
                                                  checkLoopingBack: false)
    }

    /**
     Goes to the first cell of the previous clue, then starts to apply checks to skip completed cells, checking backwards
     */
    static func goToPreviousClue(focusedTag: Binding<Int>, crossword: Crossword,
                                 goingAcross: Binding<Bool>, isHighlighted: Binding<Array<Int>>) {
        let prevClueId: String = ChangeFocusUtils.getPreviousClueID(tag: focusedTag.wrappedValue,
                                                                    crossword: crossword,
                                                                    goingAcross: goingAcross)
        let prevClueStartTag: Int = crossword.clueToTagsMap![prevClueId]!.min()!
        ChangeFocusUtils.moveFocusToFieldAndCheck(currentTag: focusedTag.wrappedValue,
                                                  tag: prevClueStartTag, crossword: crossword,
                                                  goingAcross: goingAcross, focusedTag: focusedTag,
                                                  isHighlighted: isHighlighted,
                                                  checkCluesForwards: false, checkLoopingBack: false)
    }

    static func goToLeftCell(focusedTag: Binding<Int>, crossword: Crossword,
                             goingAcross: Binding<Bool>, isHighlighted: Binding<Array<Int>>) {
        for tag in (0..<focusedTag.wrappedValue).reversed() {
            if (crossword.symbols![tag] != -1) {
                ChangeFocusUtils.changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross,
                                             focusedTag: focusedTag, isHighlighted: isHighlighted)
                return
            }
        }
    }

    private static func moveFocusToFieldAndCheck(currentTag: Int, tag: Int, crossword: Crossword,
                                                 goingAcross: Binding<Bool>, focusedTag: Binding<Int>,
                                                 isHighlighted: Binding<Array<Int>>,
                                                 checkCluesForwards: Bool, checkLoopingBack: Bool) {
        let skipCompletedCells = UserDefaults.standard.object(forKey: "skipCompletedCells") as? Bool ?? true
        var loopBackInsideCurrentWord = checkLoopingBack ? UserDefaults.standard.bool(forKey: "loopBackInsideUncompletedWord") : false
        let currentClueId = CrosswordUtils.getClueID(tag: currentTag, crossword: crossword,
                                                     goingAcross: goingAcross.wrappedValue)

        if (tag >= crossword.symbols!.count || crossword.tagToCluesMap?[tag] == nil
            || crossword.tagToCluesMap?[tag].count == 0 || crossword.entry![tag] != ""
            || tag % Int(crossword.length) == 0) {
            // the cell at the tag is not a valid empty square
            if (skipCompletedCells && !crossword.solved) {
                // skip to next uncompleted square. only makes sense if crossword isn't solved
                var possibleTag: Int = tag
                var oldTag: Int = currentTag
                for _ in (1..<crossword.entry!.count) {
                    if (possibleTag >= crossword.entry!.count
                        || crossword.symbols![possibleTag] == -1
                        || crossword.tagToCluesMap?[possibleTag] == nil
                        || crossword.tagToCluesMap?[possibleTag].count == 0
                        || ((possibleTag + 1) % Int(crossword.length) == 0 && !checkCluesForwards)
                        || (possibleTag % Int(crossword.length) == 0 && loopBackInsideCurrentWord)
                    ) {
                        // if we're checking the end, start checking again from the start
                        // if we're at a block, start checking the next clue
                        // if we're beyond the bounds of the puzzle, start checking next clue
                        // if we're going backwards and we've reached a clue that ends at the end of a row, go back a clue
                        if (loopBackInsideCurrentWord) {
                            possibleTag = crossword.clueToTagsMap![currentClueId]!.min()!
                            loopBackInsideCurrentWord = false
                            continue
                        }

                        let possibleNextClueId: String = checkCluesForwards
                            ? ChangeFocusUtils.getNextClueID(tag: oldTag, crossword: crossword,
                                                             goingAcross: goingAcross)
                            : ChangeFocusUtils.getPreviousClueID(tag: oldTag, crossword: crossword,
                                                                 goingAcross: goingAcross)
                        possibleTag = crossword.clueToTagsMap![possibleNextClueId]!.min()!
                    } else if (crossword.entry![possibleTag] == "") {
                        // if the possibleTag is empty, go there
                        ChangeFocusUtils.changeFocus(tag: possibleTag, crossword: crossword,
                                                     goingAcross: goingAcross, focusedTag: focusedTag,
                                                     isHighlighted: isHighlighted)
                        return
                    } else {
                        // possibleTag's cell is full, so move to next cell
                        oldTag = possibleTag
                        possibleTag = CrosswordUtils.getNextTag(tag: possibleTag,
                                                                goingAcross: goingAcross.wrappedValue,
                                                                crossword: crossword)
                    }
                }
                // if it reaches here, just try the cell
                ChangeFocusUtils.changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross,
                                             focusedTag: focusedTag, isHighlighted: isHighlighted)
            } else if (tag >= crossword.symbols!.count || crossword.tagToCluesMap?[tag] == nil
                       || crossword.tagToCluesMap?[tag].count == 0) {
                // they don't want to skip completed cells, so when we're at the end of the puzzle/at a square, go to start of the next clue
                let possibleNextClueId: String = checkCluesForwards
                    ? ChangeFocusUtils.getNextClueID(tag: currentTag, crossword: crossword,
                                                     goingAcross: goingAcross)
                    : ChangeFocusUtils.getPreviousClueID(tag: currentTag, crossword: crossword,
                                                         goingAcross: goingAcross)
                let nextTag = crossword.clueToTagsMap![possibleNextClueId]!.min()!
                ChangeFocusUtils.changeFocus(tag: nextTag, crossword: crossword,
                                             goingAcross: goingAcross, focusedTag: focusedTag,
                                             isHighlighted: isHighlighted)
            } else {
                // they don't want to skip completed cells, and we're checking a valid square, so just go to that square
                ChangeFocusUtils.changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross,
                                             focusedTag: focusedTag, isHighlighted: isHighlighted)
            }
        } else {
            // the cell is a valid empty square
            ChangeFocusUtils.changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross,
                                         focusedTag: focusedTag, isHighlighted: isHighlighted)
        }
    }

    private static func getNextClueID(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>) -> String {
        let directionalLetter: String = goingAcross.wrappedValue == true ? "A" : "D"
        let currentClueID = CrosswordUtils.getClueID(tag: tag, crossword: crossword,
                                                     goingAcross: goingAcross.wrappedValue)
        let currentClueNum: Int = Int(String(currentClueID.dropLast()))!
        for i in (currentClueNum+1..<crossword.clues!.count) {
            let trialClueID: String = String(i)+directionalLetter
            if crossword.clues?[trialClueID] != nil {
                return trialClueID
            }
        }
        goingAcross.wrappedValue = !goingAcross.wrappedValue
        for i in (1..<crossword.clues!.count) {
            let trialClueID: String = String(i)+String(directionalLetter == "A" ? "D" : "A")
            if crossword.clues?[trialClueID] != nil {
                return trialClueID
            }
        }
        return "1A" // should never get here
    }

    private static func getPreviousClueID(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>) -> String {
        let directionalLetter: String = goingAcross.wrappedValue == true ? "A" : "D"
        let currentClueID = CrosswordUtils.getClueID(tag: tag, crossword: crossword,
                                                     goingAcross: goingAcross.wrappedValue)
        let currentClueNum: Int = Int(String(currentClueID.dropLast()))!
        for i in (1..<currentClueNum).reversed() {
            let trialClueID: String = String(i)+directionalLetter
            if crossword.clues?[trialClueID] != nil {
                return trialClueID
            }
        }
        goingAcross.wrappedValue = !goingAcross.wrappedValue
        return String(1) + String(directionalLetter == "A" ? "D" : "A")
    }
}

// MARK: - Unused. May be used again in future, so keeping for now
/*

func goToRightCell(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    for i in (tag+1..<crossword.symbols!.count) {
        if (crossword.symbols![i] != -1) {
            changeFocus(tag: i, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
            return
        }
    }
}

func goToUpCell(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    var proposedTag = tag - Int(crossword.length)
    while(proposedTag >= 0) {
        if (crossword.symbols![proposedTag] != -1) {
            changeFocus(tag: proposedTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
            return
        }
        proposedTag -= Int(crossword.length)
    }
}

func goToDownCell(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    var proposedTag = tag + Int(crossword.length)
    while(proposedTag < crossword.symbols!.count) {
        if (crossword.symbols![proposedTag] != -1) {
            changeFocus(tag: proposedTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
            return
        }
        proposedTag += Int(crossword.length)
    }
}
 */
