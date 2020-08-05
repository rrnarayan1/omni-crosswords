//
//  CrosswordCellView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/23/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import IQKeyboardManagerSwift

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
    
    var body: some View {
        ZStack(alignment: .topLeading){
            CrosswordTextFieldView(crossword: crossword, boxWidth: self.boxWidth, rowNum: rowNum, colNum: colNum, currentClue: currentClue, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted, goingAcross: self.$goingAcross)
            if symbol > 0 {
                Text(String(symbol))
                    .font(.system(size: self.boxWidth/4))
                    .padding(self.boxWidth/25)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if (self.focusedTag == self.tag) {
                toggleDirection(tag: self.tag, crossword: self.crossword, goingAcross: self.$goingAcross, isHighlighted: self.$isHighlighted)
            } else {
                changeFocus(tag: self.tag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted)
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
    
    @Binding var focusedTag: Int
    @Binding var isHighlighted: Array<Int>
    @Binding var goingAcross: Bool
    
    func makeUIView(context: Context) -> NoActionTextField {
        let textField = NoActionTextField(frame: .zero)
        textField.tag = self.tag
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.text = self.crossword.entry?[self.tag]
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 0.25
        textField.textAlignment = NSTextAlignment.center
        textField.font = UIFont(name: "Helvetica", size: 70*boxWidth/100)
        textField.keyboardType = UIKeyboardType.alphabet
        textField.tintColor = UIColor.clear
        if (textField.text! == (".")) {
            textField.backgroundColor = UIColor.black
        }
        textField.keyboardToolbar.titleBarButton.titleColor = UIColor.black
        textField.keyboardToolbar.titleBarButton.titleFont = UIFont(name: "Helvetica", size: 14)
        textField.addTarget(context.coordinator, action: #selector(context.coordinator.touchTextFieldWhileFocused), for: .touchDown)
        return textField
    }
    
    func updateUIView(_ uiTextField: NoActionTextField, context: Context) {
        uiTextField.addKeyboardToolbarWithTarget(target: context.coordinator, titleText: self.currentClue, rightBarButtonConfiguration: IQBarButtonItemConfiguration.init(title: "hide", action: #selector(context.coordinator.hideKeyboard)), previousBarButtonConfiguration: IQBarButtonItemConfiguration.init(title: "prev", action: #selector(context.coordinator.goToPreviousClue)), nextBarButtonConfiguration: IQBarButtonItemConfiguration.init(title: "next", action: #selector(context.coordinator.goToNextClue)))
        if uiTextField.text != self.crossword.entry?[self.tag] {
            uiTextField.text = self.crossword.entry?[self.tag]
        }
        
        if focusedTag < 0 {
            uiTextField.resignFirstResponder()
        }
        
        if self.isEditable() {
            if self.tag == focusedTag {
                uiTextField.becomeFirstResponder()
            }
            if isHighlighted.contains(self.tag) {
                if (self.tag == focusedTag) {
                    uiTextField.backgroundColor = UIColor.systemGray2
                } else {
                    uiTextField.backgroundColor = UIColor.systemGray5
                }
            } else {
                uiTextField.backgroundColor = UIColor.white
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func isEditable() -> Bool {
        return self.crossword.entry![self.tag] != "."
    }
    
    func getNextClueID() -> String {
        let directionalLetter: String = self.goingAcross == true ? "A" : "D"
        let currentClueID: String = self.crossword.tagToCluesMap![self.tag][directionalLetter]!
        let currentClueNum: Int = Int(String(currentClueID.dropLast()))!
        for i in currentClueNum+1..<self.crossword.clues!.count {
            let trialClueID: String = String(i)+directionalLetter
            if self.crossword.clues?[trialClueID] != nil {
                return trialClueID
            }
        }
        return String(1)+directionalLetter
    }
    
    func getPreviousClueID() -> String {
        let directionalLetter: String = self.goingAcross == true ? "A" : "D"
        let currentClueID: String = self.crossword.tagToCluesMap![self.tag][directionalLetter]!
        let currentClueNum: Int = Int(String(currentClueID.dropLast()))!
        for i in (1..<currentClueNum).reversed() {
            let trialClueID: String = String(i)+directionalLetter
            if self.crossword.clues?[trialClueID] != nil {
                return trialClueID
            }
        }
        return String(1)+directionalLetter
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CrosswordTextFieldView
        
        @objc func touchTextFieldWhileFocused(textField: NoActionTextField) {
            print("tap on field")
            toggleDirection(tag: parent.tag, crossword: parent.crossword, goingAcross: parent.$goingAcross, isHighlighted: parent.$isHighlighted)
        }
        
        @objc func goToNextClue(textField: NoActionTextField) {
            let nextClueId: String = parent.getNextClueID()
            let nextTag: Int = parent.crossword.clueToTagsMap![nextClueId]!.min()!
            changeFocusToTag(nextTag)
        }
        
        @objc func goToPreviousClue(textField: NoActionTextField) {
            let prevClueId: String = parent.getPreviousClueID()
            let prevTag: Int = parent.crossword.clueToTagsMap![prevClueId]!.min()!
            changeFocusToTag(prevTag)
        }
        
        @objc func hideKeyboard(textField: NoActionTextField) {
            changeFocusToTag(-1)
        }

        init(_ textField: CrosswordTextFieldView) {
            self.parent = textField
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            moveFocusToNextField(textField)
            return true
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            if (!parent.isEditable()){
                return false
            }
            changeFocusToTag(parent.tag)
            return true
        }
        
        func didPressBackspace(_ textField: UITextField) {
            if (parent.focusedTag < 0) {
                return
            }
            parent.crossword.entry![parent.focusedTag] = ""
            if (parent.goingAcross) {
                changeFocusToTag(parent.focusedTag - 1)
            } else {
                changeFocusToTag(parent.focusedTag - Int(parent.crossword.length))
            }
        }
        
        func textField(_ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
            if (textField.text == "." || string == ".") {
                return false
            }
            
            if (string.isEmpty) {
                parent.crossword.entry![parent.focusedTag] = ""
                didPressBackspace(textField)
            } else {
                parent.crossword.entry![parent.focusedTag] = string.uppercased()
            }
            if (!string.isEmpty) {
                moveFocusToNextField(textField)
            }
            return false
        }
        
        func moveFocusToNextField(_ textField: UITextField) {
            if (parent.goingAcross) {
                changeFocusToTag(parent.focusedTag + 1)
            } else {
                changeFocusToTag(parent.focusedTag + Int(parent.crossword.length))
            }
        }
        
        func changeFocusToTag(_ tag: Int) {
            changeFocus(tag: tag, crossword: parent.crossword, goingAcross: parent.goingAcross, focusedTag: parent.$focusedTag, isHighlighted: parent.$isHighlighted)
        }
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

func toggleDirection(tag: Int, crossword: Crossword, goingAcross: Binding<Bool>, isHighlighted: Binding<Array<Int>>) {
    if (crossword.entry![tag] == ".") {
        return
    }
    goingAcross.wrappedValue = !goingAcross.wrappedValue
    setHighlighting(tag: tag, crossword: crossword, goingAcross: goingAcross.wrappedValue, isHighlighted: isHighlighted)
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

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
