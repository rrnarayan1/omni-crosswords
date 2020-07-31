//
//  CrosswordView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/20/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordView: View {
    var crossword: Crossword
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var focusedTag: Int = -1
    @State var highlighted: Array<Bool> = Array(repeating: false, count: 1000)
    @State var goingAcross: Bool = true
    
    var boxWidth: CGFloat {
        (UIScreen.screenWidth-15)/CGFloat(crossword.length)
    }
    
    @ViewBuilder
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach((0...self.crossword.height-1), id: \.self) { rowNum in
                    HStack (spacing: 0) {
                        ForEach((0...self.crossword.length-1), id: \.self) { colNum in
                            CrosswordCellView(
                                crossword: self.crossword,
                                boxWidth: self.boxWidth,
                                rowNum: Int(rowNum),
                                colNum: Int(colNum),
                                focusedTag: self.$focusedTag,
                                isHighlighted: self.$highlighted,
                                goingAcross: self.$goingAcross
                            ).frame(width: self.boxWidth, height: self.boxWidth)
                        }
                    }
                }
            }
            Text(getCurrentClue())
        }.navigationBarTitle(Text(self.crossword.title), displayMode: .inline)
        .onAppear {
            self.highlighted = resetArray(count: self.crossword.symbols!.count)
        }
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

struct CrosswordView_Previews: PreviewProvider {
    static var previews: some View {
        let crossword = Crossword()
        crossword.height = 3
        crossword.length = 3
        crossword.id = "id"
        crossword.entry = Array(repeating: "", count: 9)
        return CrosswordView(crossword: crossword)
    }
}

