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
    @State var highlighted: Array<Bool> = Array(repeating: false, count: 25)
    @State var goingAcross: Bool = true
    
    @ViewBuilder
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach((0...self.crossword.height-1), id: \.self) { rowNum in
                    HStack (spacing: 0) {
                        ForEach((0...self.crossword.length-1), id: \.self) { colNum in
                            CrosswordCellView(
                                crossword: self.crossword,
                                rowNum: Int(rowNum),
                                colNum: Int(colNum),
                                focusedTag: self.$focusedTag,
                                isHighlighted: self.$highlighted,
                                goingAcross: self.$goingAcross
                            ).frame(width: UIScreen.screenWidth/5, height: UIScreen.screenWidth/5)
                        }
                    }
                }
            }
        }
    }
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

