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
        textField.keyboardType = self.userSettings.useEmailAddressKeyboard
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
            ChangeFocusUtils.toggleDirection(focusedTag: self.parent.focusedTag,
                                             crossword: self.parent.crossword,
                                             goingAcross: self.parent.$goingAcross,
                                             isHighlighted: self.parent.$highlighted)
        }
        
        @objc func goToNextClue(textField: NoActionTextField) {
            self.parent.isRebusMode = false
            ChangeFocusUtils.goToNextClue(focusedTag: self.parent.$focusedTag,
                                          crossword: self.parent.crossword,
                                          goingAcross: self.parent.$goingAcross,
                                          isHighlighted: self.parent.$highlighted)
        }
        
        @objc func goToPreviousClue(textField: NoActionTextField) {
            self.parent.isRebusMode = false
            ChangeFocusUtils.goToPreviousClue(focusedTag: self.parent.$focusedTag,
                                              crossword: self.parent.crossword,
                                              goingAcross: self.parent.$goingAcross,
                                              isHighlighted: self.parent.$highlighted)
        }
        
        @objc func solveCell(textField: NoActionTextField) {
            self.parent.isRebusMode = false
            CrosswordUtils.solveCell(tag: self.parent.focusedTag, crossword: self.parent.crossword,
                                     focusedTag: self.parent.$focusedTag,
                                     goingAcross: self.parent.$goingAcross,
                                     isHighlighted: self.parent.$highlighted)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            self.parent.isRebusMode = false
            self.moveFocusToNextField()
            return true
        }
        
        func didPressBackspace(_ textField: UITextField) {
            let focusedTag = self.parent.focusedTag
            if (focusedTag < 0 || self.parent.crossword.solved)  {
                return
            }
            
            if (self.parent.crossword.entry![focusedTag] != "") {
                self.parent.crossword.entry![focusedTag] = ""
                self.parent.forceUpdate = !self.parent.forceUpdate
                self.saveGame()
            } else {
                // current cell is empty, so try to clear the previous cell
                // no matter what, we're moving cells, so exit rebus mode
                self.parent.isRebusMode = false
                let previousTag : Int = ChangeFocusUtils.getPreviousTagId(tag: focusedTag,
                                                                          goingAcross:
                                                                            self.parent.goingAcross,
                                                                          crossword:
                                                                            self.parent.crossword)
                if (previousTag >= 0 && previousTag < self.parent.crossword.entry!.count
                    && self.parent.crossword.entry![previousTag] != ".") {
                    // our current cell is empty and the previous one is valid,
                    // so clear that and go there
                    self.parent.crossword.entry![previousTag] = ""
                    self.saveGame()
                    ChangeFocusUtils.changeFocus(tag: previousTag, crossword: self.parent.crossword,
                                                 goingAcross: self.parent.$goingAcross,
                                                 focusedTag: self.parent.$focusedTag,
                                                 isHighlighted: self.parent.$highlighted)
                } else {
                    // cannot move backwards, just find some cell to go to
                    ChangeFocusUtils.goToLeftCell(focusedTag: self.parent.$focusedTag,
                                                  crossword: self.parent.crossword,
                                                  goingAcross: self.parent.$goingAcross,
                                                  isHighlighted: self.parent.$highlighted)
                }
            }
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            // invalid entry
            // string count > 1 means they probably used swipe to type, which we don't want to support
            if (self.parent.focusedTag < 0 || string == "." || string.count > 1) {
                return false
            }
            
            // Don't edit a solved crossword
            if (self.parent.crossword.solved) {
                return false
            }
            let focusedTag = self.parent.focusedTag

            if (string == " ") {
                if (self.parent.userSettings.spaceTogglesDirection) {
                    ChangeFocusUtils.toggleDirection(focusedTag: focusedTag,
                                                     crossword: self.parent.crossword,
                                                     goingAcross: self.parent.$goingAcross,
                                                     isHighlighted: self.parent.$highlighted)
                } else {
                    self.parent.isRebusMode = false
                    self.moveFocusToNextField()
                }
                return false
            } else if (string == "\t") {
                // used for tab
                self.parent.isRebusMode = false
                ChangeFocusUtils.goToNextClue(focusedTag: self.parent.$focusedTag,
                                              crossword: self.parent.crossword,
                                              goingAcross: self.parent.$goingAcross,
                                              isHighlighted: self.parent.$highlighted)
                return false
            }
            
            self.parent.crossword.solvedTime = Int16(self.parent.timerWrapper.count)

            if (string.isEmpty) {
                self.didPressBackspace(textField)
            } else {
                // it's a valid letter entered, update the crossword
                if (self.parent.isRebusMode) {
                    self.parent.forceUpdate = !self.parent.forceUpdate
                    self.parent.crossword.entry![focusedTag].append(string.uppercased())
                } else {
                    self.parent.crossword.entry![focusedTag] = string.uppercased()
                    self.moveFocusToNextField()
                }
                self.saveGame()
            }
            
            if (self.parent.crossword.entry == self.parent.crossword.solution) {
                self.parent.crossword.solved = true
                self.parent.timerWrapper.stop()
                let solvedCrossword = SolvedCrossword(context: self.parent.managedObjectContext)
                let crossword = self.parent.crossword
                solvedCrossword.date = crossword.date
                solvedCrossword.id = crossword.id
                solvedCrossword.solveTime = crossword.solvedTime
                solvedCrossword.outletName = crossword.outletName
                solvedCrossword.numClues = Int32(crossword.clues!.count)
                self.parent.focusedTag = -1
                self.parent.highlighted = Array<Int>()
                self.parent.becomeFirstResponder = false
                self.saveGame()
            }

            return false
        }
        
        func saveGame() {
            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
            if (self.parent.userSettings.shouldTryGameCenterLogin
                && self.parent.userSettings.gameCenterPlayer != nil) {
                let entryString: String = (self.parent.crossword.entry?.joined(separator: ","))!

                self.parent.userSettings.gameCenterPlayer!.saveGameData(
                    entryString.data(using: .utf8)!,
                    withName: self.parent.crossword.id!,
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
            ChangeFocusUtils.moveFocusToNextFieldAndCheck(focusedTag: self.parent.$focusedTag,
                                                          crossword: self.parent.crossword,
                                                          goingAcross: self.parent.$goingAcross,
                                                          isHighlighted: self.parent.$highlighted)
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
