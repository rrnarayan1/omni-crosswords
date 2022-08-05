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
    var isErrorTrackingEnabled: Bool
    var tag: Int {
        rowNum*Int(crossword.length)+colNum
    }
    
    var symbol: Int {
        crossword.symbols![tag]
    }
    
    @Binding var focusedTag: Int
    @Binding var highlighted: Array<Int>
    @Binding var forceUpdate: Bool
    @Binding var goingAcross: Bool
    @Binding var becomeFirstResponder: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack() {
            Color.init(self.getBackgroundColor())
            HStack(alignment: .center) {
                if (self.isEditable()) {
                    Text(crossword.entry![tag])
                        .font(.system(size: 70*boxWidth/100))
                        .frame(alignment: .center)
                }
            }
            if symbol >= 1000 {
                Circle()
                    .stroke(lineWidth: 0.5)
            }
        }
        .overlay(
            Text(symbol % 1000 > 0 ? String(symbol % 1000) : "")
                .font(.system(size: self.boxWidth/4))
                .padding(self.boxWidth/30),
            alignment: .topLeading
        )
        .onTapGesture {
            onTapCell()
        }
        .border(.black, width: 0.25)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                self.crossword.entry![self.focusedTag] = self.crossword.solution![self.focusedTag]
                if (self.crossword.entry == self.crossword.solution) {
                    self.crossword.solved = true
                }
                moveFocusToNextFieldAndCheck(currentTag: self.focusedTag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$highlighted)
           }) {
               Text("Solve Square")
           }
        }
    }
    
    func onTapCell() -> Void {
        if (!self.becomeFirstResponder) {
            self.becomeFirstResponder = true
        }
        if (!self.isEditable()) {
            return
        }
        if (self.tag == self.focusedTag) {
            toggleDirection(tag: self.tag, crossword: self.crossword, goingAcross: self.$goingAcross, isHighlighted: self.$highlighted)
        } else {
            changeFocus(tag: self.tag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$highlighted)
        }
    }
    
    func getBackgroundColor() -> UIColor {
        if (!self.isEditable()) {
            return UIColor.black
        } else if self.isErrorTrackingEnabled {
            let entry = self.crossword.entry![self.tag]
            if (entry != "" && entry != self.crossword.solution![self.tag]) {
                if self.highlighted.contains(self.tag) {
                    if (self.tag == self.focusedTag) {
                        return UIColor.systemRed.withAlphaComponent(0.6)
                    } else {
                        return UIColor.systemRed.withAlphaComponent(0.5)
                    }
                } else {
                    return UIColor.systemRed.withAlphaComponent(0.4)
                }
            }
        }
        
        if self.highlighted.contains(self.tag) {
            if (colorScheme == .dark) {
                if (self.tag == self.focusedTag) {
                    return UIColor.systemBlue.withAlphaComponent(0.8)
                } else {
                    return UIColor.systemBlue.withAlphaComponent(0.5)
                }
            } else {
                if (self.tag == self.focusedTag) {
                    return UIColor.systemBlue.withAlphaComponent(0.6)
                } else {
                    return UIColor.systemBlue.withAlphaComponent(0.2)
                }
            }
        } else {
            return self.colorScheme == .dark ? UIColor.systemGray2 : UIColor.systemBackground
        }
    }
    
    func isEditable() -> Bool {
        return self.crossword.entry![self.tag] != "."
    }
}
