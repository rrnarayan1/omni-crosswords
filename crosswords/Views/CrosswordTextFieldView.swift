//
//  CrosswordTextFieldView.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/20/21.
//  Copyright © 2021 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordTextFieldView: UIViewRepresentable {
    @EnvironmentObject var timerWrapper: TimerWrapper
    @Environment(\.managedObjectContext) var managedObjectContext

    var crossword: Crossword
    var currentClue: String
    @ObservedObject var userSettings: UserSettings

    @Binding var focusedTag: Int
    @Binding var isErrorTrackingEnabled: Bool
    @Binding var highlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var forceUpdate: Bool
    @Binding var becomeFirstResponder: Bool
    @Binding var isRebusMode: Bool
    
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

        uiTextField.changeToolbar(userSettings: self.userSettings, clueTitle: self.currentClue)
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
                                          userSettings: self.parent.userSettings,
                                          goingAcross: self.parent.$goingAcross,
                                          isHighlighted: self.parent.$highlighted)
        }
        
        @objc func goToPreviousClue(textField: NoActionTextField) {
            self.parent.isRebusMode = false
            ChangeFocusUtils.goToPreviousClue(focusedTag: self.parent.$focusedTag,
                                              crossword: self.parent.crossword,
                                              userSettings: self.parent.userSettings,
                                              goingAcross: self.parent.$goingAcross,
                                              isHighlighted: self.parent.$highlighted)
        }
        
        @objc func solveCell(textField: NoActionTextField) {
            self.parent.isRebusMode = false
            CrosswordUtils.solveCell(tag: self.parent.focusedTag, crossword: self.parent.crossword,
                                     userSettings: self.parent.userSettings,
                                     focusedTag: self.parent.$focusedTag,
                                     becomeFirstResponder: self.parent.$becomeFirstResponder,
                                     goingAcross: self.parent.$goingAcross,
                                     isHighlighted: self.parent.$highlighted,
                                     timerWrapper: self.parent.timerWrapper,
                                     managedObjectContext: self.parent.managedObjectContext)
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
            
            if (!self.parent.crossword.entry![focusedTag].isEmpty) {
                self.parent.crossword.entry![focusedTag] = ""
                self.parent.forceUpdate.toggle()
                self.saveGame()
            } else {
                // current cell is empty, so try to clear the previous cell
                // no matter what, we're moving cells, so exit rebus mode
                self.parent.isRebusMode = false
                let previousTag: Int = CrosswordUtils.getPreviousTag(tag: focusedTag,
                                                                     goingAcross:
                                                                        self.parent.goingAcross,
                                                                     crossword: self.parent.crossword)
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
                                              userSettings: self.parent.userSettings,
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
                    self.parent.forceUpdate.toggle()
                    self.parent.crossword.entry![focusedTag].append(string.uppercased())
                } else {
                    self.parent.crossword.entry![focusedTag] = string.uppercased()
                    self.moveFocusToNextField()
                    if (self.parent.isErrorTrackingEnabled
                        && self.parent.crossword.solution![focusedTag] != string.uppercased()) {
                        self.parent.crossword.helpTracking?[focusedTag] = true
                    }
                }
                self.saveGame()
            }
            
            if (self.parent.crossword.entry == self.parent.crossword.solution) {
                CrosswordUtils.solutionHandler(crossword: self.parent.crossword,
                                               shouldAddStatistics: true,
                                               userSettings: self.parent.userSettings,
                                               focusedTag: self.parent.$focusedTag,
                                               becomeFirstResponder: self.parent.$becomeFirstResponder,
                                               isHighlighted: self.parent.$highlighted,
                                               timerWrapper: self.parent.timerWrapper,
                                               managedObjectContext: self.parent.managedObjectContext)
            }

            return false
        }

        func saveGame() {
            CrosswordUtils.saveGame(crossword: self.parent.crossword,
                                    userSettings: self.parent.userSettings)
        }
        
        // checks settings and completed squares
        func moveFocusToNextField() {
            ChangeFocusUtils.moveFocusToNextFieldAndCheck(focusedTag: self.parent.$focusedTag,
                                                          crossword: self.parent.crossword,
                                                          userSettings: self.parent.userSettings,
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
