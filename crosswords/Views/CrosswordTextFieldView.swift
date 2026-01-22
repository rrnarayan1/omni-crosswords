//
//  CrosswordTextFieldView.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/20/21.
//  Copyright © 2021 Rohan Narayan. All rights reserved.
//

import SwiftUI
import GameKit

struct CrosswordTextFieldView: UIViewRepresentable {
    var crossword: Crossword
    var currentClue: String
    
    @Binding var focusedTag: Int
    @Binding var highlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var forceUpdate: Bool
    @Binding var becomeFirstResponder: Bool
    @Binding var isRebusMode: Bool
    @EnvironmentObject var timerWrapper : TimerWrapper
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var userSettings = UserSettings()
    
    func makeUIView(context: Context) -> NoActionTextField {
        let textField = NoActionTextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.keyboardType = userSettings.useEmailAddressKeyboard
            ? UIKeyboardType.emailAddress: UIKeyboardType.asciiCapable
        textField.returnKeyType = UIReturnKeyType.next
        textField.tintColor = UIColor.clear
        textField.addToolbar(coordinator: context.coordinator)
        return textField
    }
    
    func updateUIView(_ uiTextField: NoActionTextField, context: Context) {
        if (!uiTextField.isFirstResponder && self.becomeFirstResponder) {
            DispatchQueue.main.async {
                uiTextField.becomeFirstResponder()
            }
        } else if (uiTextField.isFirstResponder && !self.becomeFirstResponder) {
            DispatchQueue.main.async {
                uiTextField.resignFirstResponder()
            }
        }

        uiTextField.changeToolbar(clueTitle: self.currentClue)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CrosswordTextFieldView
        
        init(_ textField: CrosswordTextFieldView) {
            self.parent = textField
        }
        
        @objc func pressToggleButton(textField: NoActionTextField) {
            ChangeFocusUtils.toggleDirection(focusedTag: parent.focusedTag,
                                             crossword: parent.crossword,
                                             goingAcross: parent.$goingAcross,
                                             isHighlighted: parent.$highlighted)
        }
        
        @objc func goToNextClue(textField: NoActionTextField) {
            parent.isRebusMode = false
            ChangeFocusUtils.goToNextClue(focusedTag: parent.$focusedTag,
                                          crossword: parent.crossword, goingAcross: parent.$goingAcross,
                                          isHighlighted: parent.$highlighted)
        }
        
        @objc func goToPreviousClue(textField: NoActionTextField) {
            parent.isRebusMode = false
            ChangeFocusUtils.goToPreviousClue(focusedTag: parent.$focusedTag,
                                            crossword: parent.crossword, goingAcross: parent.$goingAcross,
                                            isHighlighted: parent.$highlighted)
        }
        
        @objc func solveCell(textField: NoActionTextField) {
            parent.isRebusMode = false
            CrosswordUtils.solveCell(tag: parent.focusedTag, crossword: parent.crossword,
                                     focusedTag: parent.$focusedTag, goingAcross: parent.$goingAcross,
                                     isHighlighted: parent.$highlighted)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.isRebusMode = false
            moveFocusToNextField()
            return true
        }
        
        func didPressBackspace(_ textField: UITextField) {
            if (parent.focusedTag < 0 || parent.crossword.solved)  {
                return
            }
            
            if (parent.crossword.entry![parent.focusedTag] != "") {
                parent.crossword.entry![parent.focusedTag] = ""
                parent.forceUpdate = !parent.forceUpdate
                saveGame()
            } else {
                // current cell is empty, so try to clear the previous cell
                // no matter what, we're moving cells, so exit rebus mode
                parent.isRebusMode = false
                let previousTag : Int = ChangeFocusUtils.getPreviousTagId(tag: parent.focusedTag,
                                                                          goingAcross:
                                                                            parent.goingAcross,
                                                                          crossword: parent.crossword)
                if (previousTag >= 0 && previousTag < parent.crossword.entry!.count
                    && parent.crossword.entry![previousTag] != ".") {
                    // our current cell is empty and the previous one is valid,
                    // so clear that and go there
                    parent.crossword.entry![previousTag] = ""
                    saveGame()
                    ChangeFocusUtils.changeFocus(tag: previousTag, crossword: parent.crossword,
                                                 goingAcross: parent.$goingAcross,
                                                 focusedTag: parent.$focusedTag,
                                                 isHighlighted: parent.$highlighted)
                } else {
                    // cannot move backwards, just find some cell to go to
                   ChangeFocusUtils.goToLeftCell(focusedTag: parent.$focusedTag,
                                                 crossword: parent.crossword,
                                                 goingAcross: parent.$goingAcross,
                                                 isHighlighted: parent.$highlighted)
                }
            }
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            // invalid entry
            // string count > 1 means they probably used swipe to type, which we don't want to support
            if (parent.focusedTag < 0 || string == "." || string.count > 1) {
                return false
            }
            
            // Don't edit a solved crossword
            if (parent.crossword.solved) {
                return false
            }
            
            if (string == " ") {
                if (parent.userSettings.spaceTogglesDirection) {
                    ChangeFocusUtils.toggleDirection(focusedTag: parent.focusedTag,
                                                     crossword: parent.crossword,
                                                     goingAcross: parent.$goingAcross,
                                                     isHighlighted: parent.$highlighted)
                } else {
                    parent.isRebusMode = false
                    moveFocusToNextField()
                }
                return false
            } else if (string == "\t") {
                // used for tab
                parent.isRebusMode = false
                ChangeFocusUtils.goToNextClue(focusedTag: parent.$focusedTag,
                                              crossword: parent.crossword,
                                              goingAcross: parent.$goingAcross,
                                              isHighlighted: parent.$highlighted)
                return false
            }
            
            parent.crossword.solvedTime = Int16(parent.timerWrapper.count)
            
            if (string.isEmpty) {
                didPressBackspace(textField)
            } else {
                // it's a valid letter entered, update the crossword
                if (parent.isRebusMode) {
                    parent.forceUpdate = !parent.forceUpdate
                    parent.crossword.entry![parent.focusedTag].append(string.uppercased())
                } else {
                    parent.crossword.entry![parent.focusedTag] = string.uppercased()
                    moveFocusToNextField()
                }
                saveGame()
            }
            
            if (parent.crossword.entry == parent.crossword.solution) {
                parent.crossword.solved = true
                parent.timerWrapper.stop()
                let solvedCrossword = SolvedCrossword(context: parent.managedObjectContext)
                solvedCrossword.date = parent.crossword.date
                solvedCrossword.id = parent.crossword.id
                solvedCrossword.solveTime = parent.crossword.solvedTime
                solvedCrossword.outletName = parent.crossword.outletName
                solvedCrossword.numClues = Int32(parent.crossword.clues!.count)
                parent.focusedTag = -1
                parent.highlighted = Array<Int>()
                parent.becomeFirstResponder = false
                saveGame()
            }

            return false
        }
        
        func saveGame() {
            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
            if (parent.userSettings.shouldTryGameCenterLogin && parent.userSettings.gameCenterPlayer != nil) {
                let entryString: String = (parent.crossword.entry?.joined(separator: ","))!
                
                parent.userSettings.gameCenterPlayer!.saveGameData(
                    entryString.data(using: .utf8)!,
                    withName: parent.crossword.id!,
                    completionHandler: {_, error in
                        if let error = error {
                            print("Error saving to game center: \(error)")
                        }
                    }
                )
            }
        }
        
        // checks settings and completed squares
        func moveFocusToNextField() {
            ChangeFocusUtils.moveFocusToNextFieldAndCheck(focusedTag: parent.$focusedTag,
                                                          crossword: parent.crossword,
                                                          goingAcross: parent.$goingAcross,
                                                          isHighlighted: parent.$highlighted)
        }
    }
}

class NoActionTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    override func deleteBackward() {
        if let delegate = self.delegate as? CrosswordTextFieldView.Coordinator {
            delegate.didPressBackspace(self)
        }
    }
}
