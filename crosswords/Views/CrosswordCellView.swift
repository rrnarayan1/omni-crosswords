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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("nextClue"))) { notification in
            if (self.tag == 0) {
                goToNextClue(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("previousClue"))) { notification in
            if (self.tag == 0) {
                goToPreviousClue(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("rightCell"))) { notification in
            if (self.tag == 0) {
                goToRightCell(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("leftCell"))) { notification in
            if (self.tag == 0) {
                goToLeftCell(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("upCell"))) { notification in
            if (self.tag == 0) {
                goToUpCell(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("downCell"))) { notification in
            if (self.tag == 0) {
                goToDownCell(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$isHighlighted)
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
                if (self.tag == focusedTag) {
                    uiTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
                } else {
                    uiTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
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
    
    func getNextClueID() -> String {
        return self.getNextClueID(tag: self.focusedTag)
    }
    
    func getNextClueID(tag: Int) -> String {
        return OmniCrosswords.getNextClueID(tag: tag, crossword: self.crossword, goingAcross: self.goingAcross)
    }
    
    func getPreviousClueID() -> String {
        return OmniCrosswords.getPreviousClueID(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CrosswordTextFieldView
        
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
            let nextTag: Int = getNextTagId()
            if (nextTag >= parent.crossword.symbols!.count || parent.crossword.tagToCluesMap?[nextTag] == nil || parent.crossword.tagToCluesMap?[nextTag].count == 0 || parent.crossword.entry![nextTag] != "") {
                if (parent.skipCompletedCells) {
                    // skip to next uncompleted square
                    var possibleTag: Int = getNextTagId(parent.focusedTag)
                    var oldTag: Int = parent.focusedTag
                    for _ in (1..<parent.crossword.entry!.count) {
                        if (possibleTag >= parent.crossword.entry!.count ||
                                parent.crossword.symbols![possibleTag] == -1 ||
                                parent.crossword.tagToCluesMap?[possibleTag] == nil ||
                                parent.crossword.tagToCluesMap?[possibleTag].count == 0) {
                            // if we're checking the end, start checking again from the start
                            // if we're at a block, start checking the next clue
                            // if we're beyond the bounds of the puzzle, start checking next clue
                            let possibleNextClueId: String = parent.getNextClueID(tag: oldTag)
                            possibleTag = parent.crossword.clueToTagsMap![possibleNextClueId]!.min()!
                        } else if (parent.crossword.entry![possibleTag] == "") {
                            // if the possibleTag is empty, go there
                            changeFocusToTag(possibleTag)
                            return
                        } else {
                            // possibleTag's cell is full, so move to next cell
                            oldTag = possibleTag
                            possibleTag = getNextTagId(possibleTag)
                        }
                    }
                // if it reaches here, just try the next cell
                changeFocusToTag(nextTag)
                } else if (nextTag >= parent.crossword.symbols!.count || parent.crossword.tagToCluesMap?[nextTag] == nil || parent.crossword.tagToCluesMap?[nextTag].count == 0) {
                    // they don't want to skip completed cells, so when we're at the end of the puzzle/at a square, go to start of the next clue
                    let nextClueId: String = parent.getNextClueID()
                    let nextTag: Int = parent.crossword.clueToTagsMap![nextClueId]!.min()!
                    changeFocusToTag(nextTag)
                } else {
                    // they don't want to skip completed cells, and we're checking a valid square, so just go to that square
                    changeFocusToTag(nextTag)
                }
            } else {
                // the next cell is a valid empty square
                changeFocusToTag(nextTag)
            }
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
    if (UserDefaults.standard.object(forKey: "enableHapticFeedback") as? Bool ?? true) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    goingAcross.wrappedValue = !goingAcross.wrappedValue
    setHighlighting(tag: tag, crossword: crossword, goingAcross: goingAcross.wrappedValue, isHighlighted: isHighlighted)
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

func goToNextClue(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    if (UserDefaults.standard.object(forKey: "enableHapticFeedback") as? Bool ?? true) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    let nextClueId: String = getNextClueID(tag: tag, crossword: crossword, goingAcross: goingAcross)
    let nextTag: Int = crossword.clueToTagsMap![nextClueId]!.min()!
    changeFocus(tag: nextTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
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
    while(proposedTag > 0) {
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

func goToPreviousClue(tag: Int, crossword: Crossword, goingAcross: Bool, focusedTag: Binding<Int>, isHighlighted: Binding<Array<Int>>) {
    if (UserDefaults.standard.object(forKey: "enableHapticFeedback") as? Bool ?? true) {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    let prevClueId: String = getPreviousClueID(tag: tag, crossword: crossword, goingAcross: goingAcross)
    let prevTag: Int = crossword.clueToTagsMap![prevClueId]!.min()!
    changeFocus(tag: prevTag, crossword: crossword, goingAcross: goingAcross, focusedTag: focusedTag, isHighlighted: isHighlighted)
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
