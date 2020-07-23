//
//  CrosswordView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/20/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordView: View {
    @State var crossword: Crossword
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var focused: Array<Bool> = Array(repeating: false, count: 25)
    
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach((1...self.crossword.height), id: \.self) { rowNum in
                HStack (spacing: 0) {
                    ForEach((1...self.crossword.length), id: \.self) { colNum in
                        CrosswordTextFieldView(
                            crossword: self.crossword,
                            rowNum: Int(rowNum) - 1,
                            colNum: Int(colNum) - 1,
                            isFocusable: self.$focused
                        ).frame(width: UIScreen.screenWidth/5, height: UIScreen.screenWidth/5)
                    }
                }
            }
        }
    }
}

struct CrosswordTextFieldView: UIViewRepresentable {
    var crossword: Crossword
    var rowNum: Int
    var colNum: Int
    var tag: Int {
        rowNum*5+colNum
    }
    
    @Binding var isFocusable: Array<Bool>
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.tag = self.tag
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.text = self.crossword.entry?[self.rowNum][self.colNum]
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
        textField.textAlignment = NSTextAlignment.center
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != self.crossword.entry?[self.rowNum][self.colNum] {
            self.crossword.entry?[self.rowNum][self.colNum] = uiView.text!
        }
        if isFocusable[tag] {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CrosswordTextFieldView

        init(_ textField: CrosswordTextFieldView) {
            self.parent = textField
        }

        func updatefocus(textfield: UITextField) {
            textfield.becomeFirstResponder()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            var newFocus = Array(repeating: false, count: 25)
            newFocus[parent.tag+1] = true
            parent.isFocusable = newFocus
            return true
        }
        
        func textField(_ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
            textField.text = string.uppercased()
            if (!string.isEmpty) {
                textFieldShouldReturn(textField)
            }
            return false
        }
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

struct CrosswordView_Previews: PreviewProvider {
    static var previews: some View {
        let crossword = Crossword()
        crossword.height = 5
        crossword.length = 5
        crossword.id = 1
        crossword.entry = Array(repeating: Array(repeating: "", count: 5), count: 5)
        return CrosswordView(crossword: crossword)
    }
}

