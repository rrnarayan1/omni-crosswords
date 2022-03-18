//
//  ChangeFocusUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/20/21.
//  Copyright © 2021 Rohan Narayan. All rights reserved.
//

import SwiftUI

func moveFocusToNextFieldAndCheck(currentTag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>,
                          isHighlighted: Binding<Array<Int>>) {
    let nextTag: Int = getNextTagId(tag: currentTag, goingAcross: goingAcross, crossword: crossword)
    moveFocusToFieldAndCheck(currentTag: currentTag, tag: nextTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted, checkCluesForwards: true)
}

func moveFocusToFieldAndCheck(currentTag: Int, tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>,
                              isHighlighted: Binding<Array<Int>>, checkCluesForwards: Bool) {
    let skipCompletedCells = UserDefaults.standard.object(forKey: "skipCompletedCells") as? Bool ?? true
    
    if (tag >= crossword.symbols!.count || crossword.tagToCluesMap?[tag] == nil || crossword.tagToCluesMap?[tag].count == 0 || crossword.entry![tag] != "") {
        if (skipCompletedCells) {
            // skip to next uncompleted square
            var possibleTag: Int = tag
            var oldTag: Int = currentTag
            for _ in (1..<crossword.entry!.count) {
                if (possibleTag >= crossword.entry!.count ||
                        crossword.symbols![possibleTag] == -1 ||
                        crossword.tagToCluesMap?[possibleTag] == nil ||
                        crossword.tagToCluesMap?[possibleTag].count == 0 ||
                    ((possibleTag + 1) % Int(crossword.length) == 0 && !checkCluesForwards)) {
                    // if we're checking the end, start checking again from the start
                    // if we're at a block, start checking the next clue
                    // if we're beyond the bounds of the puzzle, start checking next clue
                    // if we're going backwards and we've reached a clue that ends at the end of a row, go back a clue
                    let possibleNextClueId: String = checkCluesForwards
                        ? getNextClueID(tag: oldTag, crossword: crossword, goingAcross: goingAcross)
                        : getPreviousClueID(tag: oldTag, crossword: crossword, goingAcross: goingAcross)
                    possibleTag = crossword.clueToTagsMap![possibleNextClueId]!.min()!
                } else if (crossword.entry![possibleTag] == "") {
                    // if the possibleTag is empty, go there
                    changeFocus(tag: possibleTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
                    return
                } else {
                    // possibleTag's cell is full, so move to next cell
                    oldTag = possibleTag
                    possibleTag = getNextTagId(tag: possibleTag, goingAcross: goingAcross, crossword: crossword)
                }
            }
            // if it reaches here, just try the cell
            changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
        } else if (tag >= crossword.symbols!.count || crossword.tagToCluesMap?[tag] == nil || crossword.tagToCluesMap?[tag].count == 0) {
            // they don't want to skip completed cells, so when we're at the end of the puzzle/at a square, go to start of the next clue
            let possibleNextClueId: String = checkCluesForwards
                ? getNextClueID(tag: currentTag, crossword: crossword, goingAcross: goingAcross)
                : getPreviousClueID(tag: currentTag, crossword: crossword, goingAcross: goingAcross)
            let nextTag = crossword.clueToTagsMap![possibleNextClueId]!.min()!
            changeFocus(tag: nextTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
        } else {
            // they don't want to skip completed cells, and we're checking a valid square, so just go to that square
            changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
        }
    } else {
        // the cell is a valid empty square
        changeFocus(tag: tag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
    }
}

func changeFocus(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>,
                      isHighlighted: Binding<Array<Int>>) {
    if (tag < 0 || tag >= crossword.symbols!.count || crossword.tagToCluesMap?[tag] == nil
        || crossword.tagToCluesMap?[tag].count == 0) {
        focusedTag.wrappedValue = -1
        isHighlighted.wrappedValue = Array<Int>()
        return
    }
    focusedTag.wrappedValue = tag
    setHighlighting(tag: tag, crossword: crossword, goingAcross: goingAcross, isHighlighted: isHighlighted)
}

func getNextTagId(tag: Int, goingAcross: Bool, crossword: Crossword) -> Int {
    if (goingAcross) {
        return tag + 1
    } else {
        return tag + Int(crossword.length)
    }
}

func getPreviousTagId(tag: Int, goingAcross: Bool, crossword: Crossword) -> Int {
    if (goingAcross) {
        return tag - 1
    } else {
        return tag - Int(crossword.length)
    }
}

func toggleDirection(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>, isHighlighted: Binding<Array<Int>>) {
    if (crossword.entry![tag] == ".") {
        return
    }
    if (UserDefaults.standard.object(forKey: "enableHapticFeedback") as? Bool ?? true) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    goingAcross.wrappedValue = !goingAcross.wrappedValue
    setHighlighting(tag: tag, crossword: crossword, goingAcross: goingAcross.wrappedValue, isHighlighted: isHighlighted)
}

func goToNextClue(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    if (UserDefaults.standard.object(forKey: "enableHapticFeedback") as? Bool ?? true) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    let nextClueId: String = getNextClueID(tag: tag, crossword: crossword, goingAcross: goingAcross)
    let nextClueStartTag: Int = crossword.clueToTagsMap![nextClueId]!.min()!
    moveFocusToFieldAndCheck(currentTag: tag, tag: nextClueStartTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted, checkCluesForwards: true)
}

func goToPreviousClue(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    if (UserDefaults.standard.object(forKey: "enableHapticFeedback") as? Bool ?? true) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    let prevClueId: String = getPreviousClueID(tag: tag, crossword: crossword, goingAcross: goingAcross)
    let prevClueStartTag: Int = crossword.clueToTagsMap![prevClueId]!.min()!
    moveFocusToFieldAndCheck(currentTag: tag, tag: prevClueStartTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted, checkCluesForwards: false)
}

func getNextClueID(tag: Int, crossword: Crossword, goingAcross: Bool) -> String {
    let directionalLetter: String = goingAcross == true ? "A" : "D"
    let currentClueID: String = crossword.tagToCluesMap![tag][directionalLetter]!
    let currentClueNum: Int = Int(String(currentClueID.dropLast()))!
    for i in (currentClueNum+1..<crossword.clues!.count) {
        let trialClueID: String = String(i)+directionalLetter
        if crossword.clues?[trialClueID] != nil {
            return trialClueID
        }
    }
    return String(1)+directionalLetter
}

func getPreviousClueID(tag: Int, crossword: Crossword, goingAcross: Bool) -> String {
    let directionalLetter: String = goingAcross == true ? "A" : "D"
    let currentClueID: String = crossword.tagToCluesMap![tag][directionalLetter]!
    let currentClueNum: Int = Int(String(currentClueID.dropLast()))!
    for i in (1..<currentClueNum).reversed() {
        let trialClueID: String = String(i)+directionalLetter
        if crossword.clues?[trialClueID] != nil {
            return trialClueID
        }
    }
    return String(1)+directionalLetter
}

func goToRightCell(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    for i in (tag+1..<crossword.symbols!.count) {
        if (crossword.symbols![i] != -1) {
            changeFocus(tag: i, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
            return
        }
    }
}

func goToLeftCell(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    for i in (0..<tag).reversed() {
        if (crossword.symbols![i] != -1) {
            changeFocus(tag: i, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
            return
        }
    }
}

func goToUpCell(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    var proposedTag = tag - Int(crossword.length)
    while(proposedTag >= 0) {
        if (crossword.symbols![proposedTag] != -1) {
            changeFocus(tag: proposedTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
            return
        }
        proposedTag -= Int(crossword.length)
    }
}

func goToDownCell(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    var proposedTag = tag + Int(crossword.length)
    while(proposedTag < crossword.symbols!.count) {
        if (crossword.symbols![proposedTag] != -1) {
            changeFocus(tag: proposedTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
            return
        }
        proposedTag += Int(crossword.length)
    }
}

func setHighlighting(tag: Int, crossword: Crossword, goingAcross: Bool, isHighlighted: Binding<Array<Int>>) {
    var newHighlighted = Array<Int>()
    newHighlighted.append(tag)
    
    let clues: Dictionary<String, String> = (crossword.tagToCluesMap?[tag])!
    let directionalLetter: String = goingAcross ? "A" : "D"
    let clue: String = clues[directionalLetter]!
    let clueTags: Array<Int> = (crossword.clueToTagsMap?[clue])!
    for clueTag in clueTags {
        newHighlighted.append(clueTag)
    }
    isHighlighted.wrappedValue = newHighlighted
}
