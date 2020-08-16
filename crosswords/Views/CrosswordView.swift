//
//  CrosswordView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/20/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import IQKeyboardManagerSwift

struct CrosswordView: View {
    var crossword: Crossword
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var focusedTag: Int = -1
    @State var highlighted: Array<Int> = Array()
    @State var goingAcross: Bool = true
    
    var boxWidth: CGFloat {
        (UIScreen.screenWidth-5)/CGFloat(crossword.length)
    }
    
    var displayTitle: String {
        let date = self.crossword.date!
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateStyle = .short
        var prefix: String = ""
        if (self.crossword.solved) {
            prefix = "Solved: "
        }
        return prefix + self.crossword.outletName! + " - " + formatter.string(from: date)
    }
    
    @ViewBuilder
    var body: some View {
        VStack{
            ScrollView {
                { () -> CrosswordGridView in
                    let currentClue = getCurrentClue()
                    return CrosswordGridView(crossword: self.crossword, boxWidth: self.boxWidth, currentClue: currentClue, focusedTag: self.$focusedTag, highlighted: self.$highlighted, goingAcross: self.$goingAcross)
                }()
                .padding(.top, 30)
            }
            Spacer()
            Text(self.crossword.title!)
            Text(self.crossword.author!)
            if (self.crossword.notes! != "") {
                Text(self.crossword.notes!)
            }
            Text(self.crossword.copyright!)
        }
            .navigationBarTitle(Text(verbatim: displayTitle), displayMode: .inline)
    }
    
    func resetArray(count: Int) -> Array<Bool> {
        return Array(repeating: false, count: count)
    }
    
    func getCurrentClue() -> String {
        if (self.focusedTag < 0 || self.crossword.tagToCluesMap?[self.focusedTag] == nil) {
            return ""
        }
        let possibleClues : Dictionary<String, String> = (self.crossword.tagToCluesMap?[self.focusedTag])!
        let directionalLetter : String = self.goingAcross ? "A" : "D"
        return self.crossword.clues![possibleClues[directionalLetter]!]!
    }
}

struct CrosswordGridView: View {
    var crossword: Crossword
    var boxWidth: CGFloat
    var currentClue: String
    
    @Binding var focusedTag: Int
    @Binding var highlighted: Array<Int>
    @Binding var goingAcross: Bool
    
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach((0...self.crossword.height-1), id: \.self) { rowNum in
                HStack (spacing: 0) {
                    ForEach((0...self.crossword.length-1), id: \.self) { colNum in
                        CrosswordCellView(
                            crossword: self.crossword,
                            boxWidth: self.boxWidth,
                            rowNum: Int(rowNum),
                            colNum: Int(colNum),
                            currentClue: self.currentClue, focusedTag: self.$focusedTag,
                            isHighlighted: self.$highlighted,
                            goingAcross: self.$goingAcross
                        ).frame(width: self.boxWidth, height: self.boxWidth)
                    }
                }
            }
        }
    }
}
