//
//  CrosswordCellView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/23/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordCellView: View {
    var crossword: Crossword
    var boxWidth: CGFloat
    var rowNum: Int
    var colNum: Int
    var tag: Int {
        rowNum*Int(crossword.length)+colNum
    }
    
    var symbol: Int {
        crossword.symbols![tag]
    }
    
    @Binding var focusedTag: Int
    @Binding var isHighlighted: Array<Bool>
    @Binding var goingAcross: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading){
            CrosswordTextFieldView(crossword: crossword, boxWidth: self.boxWidth, rowNum: rowNum, colNum: colNum, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted, goingAcross: self.$goingAcross)
            if symbol > 0 {
                Text(String(symbol))
                    .font(.system(size: self.boxWidth/4))
                    .padding(self.boxWidth/10)
            }
        }
    }
}

struct CrosswordTextFieldView: UIViewRepresentable {
    var crossword: Crossword
    var boxWidth: CGFloat
    var rowNum: Int
    var colNum: Int
    var tag: Int {
        rowNum*Int(crossword.length)+colNum
    }
    
    @Binding var focusedTag: Int
    @Binding var isHighlighted: Array<Bool>
    @Binding var goingAcross: Bool
    
    func makeUIView(context: Context) -> NoActionTextField {
        let textField = NoActionTextField(frame: .zero)
        textField.tag = self.tag
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.text = self.crossword.entry?[self.tag]
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
        textField.textAlignment = NSTextAlignment.center
        textField.font = UIFont(name: textField.font!.fontName, size: boxWidth/2)
        textField.keyboardType = UIKeyboardType.alphabet
        textField.tintColor = UIColor.clear
        if (textField.text! == (".")) {
            textField.backgroundColor = UIColor.black
        }
        textField.addTarget(context.coordinator, action: #selector(context.coordinator.touchTextFieldWhileFocused), for: .touchDown)
        return textField
    }
    
    func updateUIView(_ uiTextField: NoActionTextField, context: Context) {
        if uiTextField.text != self.crossword.entry?[self.tag] {
            self.crossword.entry?[self.tag] = uiTextField.text!
        }
        
        if self.isEditable() {
            if self.tag == focusedTag {
                uiTextField.becomeFirstResponder()
            } else {
                uiTextField.resignFirstResponder()
            }
            if isHighlighted[tag] {
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
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CrosswordTextFieldView
        
        @objc func touchTextFieldWhileFocused(textField: NoActionTextField) {
            parent.goingAcross = !parent.goingAcross
            setHighlighting(parent.tag)
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
        
        func textField(_ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
            if (textField.text == ".") {
                return false
            }
            textField.text = string.uppercased()
            if (!string.isEmpty) {
                moveFocusToNextField(textField)
            }
            return false
        }
        
        func moveFocusToNextField(_ textField: UITextField) {
            if (parent.goingAcross) {
                changeFocusToTag(parent.tag + 1)
            } else {
                changeFocusToTag(parent.tag + Int(parent.crossword.length))
            }
        }
        
        func changeFocusToTag(_ tag: Int) {
            if (tag >= parent.crossword.symbols!.count) {
                parent.focusedTag = -1
                parent.isHighlighted = Array(repeating: false, count: parent.crossword.symbols!.count)
                return
            }
            parent.focusedTag = tag
            if (parent.crossword.tagToCluesMap?[tag] == nil || parent.crossword.tagToCluesMap?[tag].count == 0) {
                parent.focusedTag = -1
                parent.isHighlighted = Array(repeating: false, count: parent.crossword.symbols!.count)
                return
            }
            setHighlighting(tag)
        }
        
        func setHighlighting(_ tag: Int) {
            var newHighlighted = Array(repeating: false, count: parent.crossword.symbols!.count)
            newHighlighted[tag] = true
            
            let clues: Dictionary<String, String> = (parent.crossword.tagToCluesMap?[tag])!
            let directionalLetter : String = parent.goingAcross ? "A" : "D"
            let clue: String = clues[directionalLetter]!
            let clueTags: Array<Int> = (parent.crossword.clueToTagsMap?[clue])!
            for clueTag in clueTags {
                newHighlighted[clueTag] = true
            }
            parent.isHighlighted = newHighlighted
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
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
