//
//  CrosswordCellView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/23/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import FontAwesome_swift

struct CrosswordCellView: View {
    var crossword: Crossword
    var boxWidth: CGFloat
    var rowNum: Int
    var colNum: Int
    var currentClue: String
    var tag: Int {
        rowNum*Int(crossword.length)+colNum
    }
    
    var symbol: Int {
        crossword.symbols![tag]
    }
    
    @Binding var focusedTag: Int
    @Binding var isHighlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var doErrorTracking: Bool
    @Binding var forceUpdate: Bool
    @Binding var isKeyboardOpen: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading){
            CrosswordTextFieldView(crossword: crossword, boxWidth: self.boxWidth, rowNum: rowNum, colNum: colNum, currentClue: currentClue, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted, goingAcross: self.$goingAcross, doErrorTracking: self.$doErrorTracking, forceUpdate: self.$forceUpdate, isKeyboardOpen: self.$isKeyboardOpen)
            if symbol % 1000 > 0 {
                Text(String(symbol % 1000))
                    .font(.system(size: self.boxWidth/4))
                    .padding(self.boxWidth/25)
            }
            if symbol >= 1000 {
                Circle()
                    .stroke(lineWidth: 0.5)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                self.crossword.entry![self.focusedTag] = self.crossword.solution![self.focusedTag]
                if (self.crossword.entry == self.crossword.solution) {
                    self.crossword.solved = true
                }
           }) {
               Text("Solve Square")
           }
        }
    }
}

struct CrosswordTextFieldView: UIViewRepresentable {
    var crossword: Crossword
    var boxWidth: CGFloat
    var rowNum: Int
    var colNum: Int
    var currentClue: String
    var tag: Int {
        rowNum*Int(crossword.length)+colNum
    }
    
    var toggleImage: UIImage {
        if (self.goingAcross) {
            return UIImage.fontAwesomeIcon(name: .arrowsAltV, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize(width: 25, height: 25))
        } else {
            return UIImage.fontAwesomeIcon(name: .arrowsAltH, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize(width: 25, height: 25))
        }
    }
    
    var skipCompletedCells: Bool {
        UserDefaults.standard.object(forKey: "skipCompletedCells") as? Bool ?? true
    }
    
    
    @Binding var focusedTag: Int
    @Binding var isHighlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var doErrorTracking: Bool
    @Binding var forceUpdate: Bool
    @Binding var isKeyboardOpen: Bool
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var timerWrapper : TimerWrapper
    @ObservedObject var userSettings = UserSettings()
    
    func makeUIView(context: Context) -> NoActionTextField {
        let textField = NoActionTextField(frame: .zero)
        textField.tag = self.tag
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.text = self.crossword.entry?[self.tag]
        textField.layer.borderColor = UIColor.label.cgColor
        textField.layer.borderWidth = 0.25
        textField.textAlignment = NSTextAlignment.center
        textField.font = UIFont(name: "Helvetica", size: 70*boxWidth/100)
        textField.keyboardType = UIKeyboardType.alphabet
        textField.tintColor = UIColor.clear
        if (textField.text! == (".")) {
            textField.textColor = UIColor.black
            textField.backgroundColor = UIColor.black
        }
        
        textField.addTarget(context.coordinator, action: #selector(context.coordinator.touchTextFieldWhileFocused), for: .allTouchEvents)
        textField.addToolbar()
        return textField
    }
    
    func updateUIView(_ uiTextField: NoActionTextField, context: Context) {
        if (uiTextField.isFirstResponder) {
            if (!uiTextField.gestureRecognizers!.contains(where: { (gestureRecognizer) -> Bool in
                gestureRecognizer is SingleTouchDownGestureRecognizer
            })) {
                let gesture = SingleTouchDownGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.touchTextFieldWhileFocused))
                uiTextField.addGestureRecognizer(gesture)
            }
            let currentClueForce = self.forceUpdate ? currentClue : currentClue + " "
            uiTextField.changeToolbar(clueTitle: currentClueForce, toggleImage: toggleImage, coordinator: context.coordinator, barColor: self.crossword.solved ? UIColor.systemGreen : UIColor.systemGray6)
        }

        if uiTextField.text != self.crossword.entry?[self.tag] {
            uiTextField.text = self.crossword.entry?[self.tag]
        }

        if focusedTag < 0 {
            uiTextField.resignFirstResponder()
        }
        
        if self.isEditable() {
            if isHighlighted.contains(self.tag) {
                if (colorScheme == .dark) {
                    if (self.tag == focusedTag) {
                        uiTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
                    } else {
                        uiTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
                    }
                } else {
                    if (self.tag == focusedTag) {
                        uiTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.6)
                    } else {
                        uiTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                    }
                }
            } else {
                uiTextField.backgroundColor = colorScheme == .dark ? UIColor.systemGray2 : UIColor.systemBackground
            }
        }
        
        if self.doErrorTracking {
            let entry = self.crossword.entry![self.tag]
            if (entry != "" && entry != self.crossword.solution![self.tag]) {
                if isHighlighted.contains(self.tag) {
                    if (self.tag == focusedTag) {
                        uiTextField.backgroundColor = UIColor.systemRed.withAlphaComponent(0.6)
                    } else {
                        uiTextField.backgroundColor = UIColor.systemRed.withAlphaComponent(0.5)
                    }
                } else {
                    uiTextField.backgroundColor = UIColor.systemRed.withAlphaComponent(0.4)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func isEditable() -> Bool {
        return self.crossword.entry![self.tag] != "."
    }
    
    func getNextClueID(tag: Int) -> String {
        return OmniCrosswords.getNextClueID(tag: tag, crossword: self.crossword, goingAcross: self.goingAcross)
    }
    
    func getPreviousClueID() -> String {
        return OmniCrosswords.getPreviousClueID(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CrosswordTextFieldView
        
        init(_ textField: CrosswordTextFieldView) {
            self.parent = textField
        }
        
        @objc func touchTextFieldWhileFocused(textField: NoActionTextField) {
            if (parent.tag == parent.focusedTag) {
                toggleDirection(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, isHighlighted: parent.$isHighlighted)
            } else {
                changeFocusToTag(parent.tag)
            }
        }
        
        @objc func pressToggleButton(textField: NoActionTextField) {
            toggleDirection(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, isHighlighted: parent.$isHighlighted)
        }
        
        @objc func goToNextClue(textField: NoActionTextField) {
            OmniCrosswords.goToNextClue(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$isHighlighted)
        }
        
        @objc func goToPreviousClue(textField: NoActionTextField) {
            OmniCrosswords.goToPreviousClue(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$isHighlighted)
        }
        
        @objc func hideKeyboard(textField: NoActionTextField) {
            changeFocusToTag(-1)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            moveFocusToNextField(textField)
            return true
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            if (!parent.isEditable()){
                return false
            }
            
            if (parent.focusedTag == parent.tag) {
                toggleDirection(tag: parent.tag, crossword: parent.crossword, goingAcross: parent.$goingAcross, isHighlighted: parent.$isHighlighted)
            }
                
            changeFocusToTag(parent.tag)
            if (parent.isKeyboardOpen) {
                return false
            } else {
                parent.isKeyboardOpen = true
                return true
            }
        }
        
        func didPressBackspace(_ textField: UITextField) {
            if (parent.focusedTag < 0) {
                return
            }
            
            if (parent.crossword.entry![parent.focusedTag] != "") {
                parent.crossword.entry![parent.focusedTag] = ""
                parent.forceUpdate = !parent.forceUpdate
            } else {
                var previousTag : Int = parent.goingAcross ? parent.focusedTag - 1 : parent.focusedTag - Int(parent.crossword.length)
                if (previousTag >= 0 && previousTag < parent.crossword.entry!.count && parent.crossword.entry![previousTag] != ".") {
                    parent.crossword.entry![previousTag] = ""
                    changeFocusToTag(previousTag)
                } else {
                    let prevClueId: String = parent.getPreviousClueID()
                    previousTag = parent.crossword.clueToTagsMap![prevClueId]!.max()!
                    changeFocusToTag(previousTag)
                }
            }
        }
        
        func textField(_ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
            if (textField.text == "." || string == "." || parent.focusedTag < 0) {
                return false
            }
            
            if (string == " " && parent.userSettings.spaceTogglesDirection) {
                toggleDirection(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.$goingAcross, isHighlighted: parent.$isHighlighted)
                return false
            }
            
            if (string == " ") {
                moveFocusToNextField(textField)
                return false
            }
            
            if (string.isEmpty) {
                didPressBackspace(textField)
            } else {
                parent.crossword.entry![parent.focusedTag] = string.uppercased()
            }
            
            if (parent.crossword.entry == parent.crossword.solution) {
                parent.crossword.solved = true
                parent.timerWrapper.stop()
            } else if (parent.crossword.solved) {
                parent.crossword.solved = false
            }
            parent.crossword.solvedTime = Int16(parent.timerWrapper.count)
            
            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
            
            if (!string.isEmpty) {
                moveFocusToNextField(textField)
            }
            return false
        }
        
        func moveFocusToNextField(_ textField: UITextField) {
            OmniCrosswords.moveFocusToNextField(tag: parent.focusedTag, crossword: parent.crossword, goingAcross: parent.goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$isHighlighted)
        }
        
        func getNextTagId() -> Int {
            return getNextTagId(parent.focusedTag)
        }
        
        func getNextTagId(_ tag: Int) -> Int {
            if (parent.goingAcross) {
                return tag + 1
            } else {
                return tag + Int(parent.crossword.length)
            }
        }
        
        // does not take settings / completed squares into account
        func changeFocusToTag(_ tag: Int) {
            changeFocus(tag: tag, crossword: parent.crossword, goingAcross: parent.goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$isHighlighted)
        }
    }
}

class NoActionTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        OperationQueue.main.addOperation {
            UIMenuController.shared.setMenuVisible(false, animated: false)
        }
        return false
    }
    
    override func deleteBackward() {
        if let delegate = self.delegate as? CrosswordTextFieldView.Coordinator {
            delegate.didPressBackspace(self)
        }
    }
}

class SingleTouchDownGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible {
            self.state = .recognized
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
