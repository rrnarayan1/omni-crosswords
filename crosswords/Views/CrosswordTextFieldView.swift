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
    
    let downArrowImage = UIImage(systemName: "arrow.up.arrow.down")!.imageWith(newSize: CGSize(width: 18.0, height: 18.0))
    let acrossArrowImage = UIImage(systemName: "arrow.left.arrow.right")!.imageWith(newSize: CGSize(width: 18.0, height: 18.0))
    
    var toggleImage: UIImage {
        var image: UIImage
        if (self.goingAcross) {
            image = downArrowImage
        } else {
            image = acrossArrowImage
        }
        return image
    }
    
    @Binding var focusedTag: Int
    @Binding var highlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var forceUpdate: Bool
    @Binding var becomeFirstResponder: Bool
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var timerWrapper : TimerWrapper
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var userSettings = UserSettings()
    
    func makeUIView(context: Context) -> NoActionTextField {
        let textField = NoActionTextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.keyboardType = userSettings.useEmailAddressKeyboard ? UIKeyboardType.emailAddress: UIKeyboardType.asciiCapable
        textField.returnKeyType = UIReturnKeyType.next
        textField.tintColor = UIColor.clear
        textField.addToolbar(coordinator: context.coordinator, clueTitle: "", toggleImage: self.toggleImage, barColor: self.crossword.solved ? UIColor.systemGreen : UIColor.systemGray6)
        return textField
    }
    
    func updateUIView(_ uiTextField: NoActionTextField, context: Context) {
        if (!uiTextField.isFirstResponder && self.becomeFirstResponder) {
            DispatchQueue.main.async {
                uiTextField.becomeFirstResponder()
            }
        } else if (self.becomeFirstResponder == false && uiTextField.isFirstResponder) {
            DispatchQueue.main.async {
                uiTextField.resignFirstResponder()
            }
        }

        let currentClueForce = self.forceUpdate ? currentClue : currentClue + " "
        uiTextField.changeToolbar(clueTitle: currentClueForce, toggleImage: toggleImage, barColor: self.crossword.solved ? UIColor.systemGreen : UIColor.systemGray6)
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
            toggleDirection(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, isHighlighted: parent.$highlighted)
        }
        
        @objc func goToNextClue(textField: NoActionTextField) {
            OmniCrosswords.goToNextClue(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$highlighted)
        }
        
        @objc func goToPreviousClue(textField: NoActionTextField) {
            OmniCrosswords.goToPreviousClue(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$highlighted)
        }
        
        @objc func solveCell(textField: NoActionTextField) {
            OmniCrosswords.solveCell(tag: parent.focusedTag, crossword: parent.crossword, focusedTag: parent.$focusedTag, goingAcross: parent.$goingAcross, isHighlighted: parent.$highlighted)
        }
        
        @objc func isSolutionAvailable(textField: NoActionTextField) -> Bool {
            return OmniCrosswords.isSolutionAvailable(crossword: parent.crossword)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            moveFocusToNextField(textField)
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
                var previousTag : Int = parent.goingAcross ? parent.focusedTag - 1 : parent.focusedTag - Int(parent.crossword.length)
                if (previousTag >= 0 && previousTag < parent.crossword.entry!.count && parent.crossword.entry![previousTag] != ".") {
                    // move backwards
                    parent.crossword.entry![previousTag] = ""
                    saveGame()
                    changeFocusToTag(previousTag)
                } else {
                    // cannot move backwards, go back one clue
                    let prevClueId: String = getPreviousClueID(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross)
                    previousTag = parent.crossword.clueToTagsMap![prevClueId]!.max()!
                    changeFocusToTag(previousTag)
                }
            }
        }
        
        func textField(_ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
            // invalid entry
            if (parent.focusedTag < 0 || string == ".") {
                return false
            }
            // probably used swipe to type, which we don't want to support
            if (string.count > 1) {
                return false
            }
            
            if (string == " " && parent.userSettings.spaceTogglesDirection) {
                toggleDirection(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, isHighlighted: parent.$highlighted)
                return false
            }
            
            if (string == " ") {
                moveFocusToNextField(textField)
                return false
            } else if (string == "\t") {
                goToNextClue(textField)
                return false
            }
            
            if (parent.crossword.solved) {
                // Don't edit a solved crossword
                return false
            }
            parent.crossword.solvedTime = Int16(parent.timerWrapper.count)
            
            if (string.isEmpty) {
                didPressBackspace(textField)
            } else {
                parent.crossword.entry![parent.focusedTag] = string.uppercased()
                moveFocusToNextField(textField)
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
                changeFocusToTag(-1)
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
        func moveFocusToNextField(_ textField: UITextField) {
            OmniCrosswords.moveFocusToNextFieldAndCheck(currentTag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$highlighted)
        }
        
        // does not take settings / completed squares into account
        func changeFocusToTag(_ tag: Int) {
            changeFocus(tag: tag, crossword: parent.crossword, goingAcross: parent.$goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$highlighted)
        }

        func goToNextClue(_ textField: UITextField) {
            OmniCrosswords.goToNextClue(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$highlighted)
        }
    }
}

class NoActionTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        OperationQueue.main.addOperation {
            UIMenuController.shared.hideMenu()
        }
        return false
    }
    
    override func deleteBackward() {
        if let delegate = self.delegate as? CrosswordTextFieldView.Coordinator {
            delegate.didPressBackspace(self)
        }
    }
}
