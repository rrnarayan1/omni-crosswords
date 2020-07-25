//
//  DataBuilder.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/24/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import Foundation

func buildCrossword(crossword: Crossword) -> Void {
    crossword.length = 5
    crossword.height = 5
    crossword.id = 1
    crossword.entry = Array(repeating: Array(repeating: "", count: 5), count: 5)
    crossword.entry![0][0] = "XXX"
    crossword.entry![0][4] = "XXX"
    crossword.entry![4][0] = "XXX"
    crossword.entry![4][4] = "XXX"
    crossword.symbols =
    [
        [-1, 1, 2, 3, -1], // 5 elements!
        [4, 0, 0, 0, 5],
        [6, 0, 0, 0, 0],
        [7, 0, 0, 0, 0],
        [-1, 8, 0, 0, -1]
    ]
    
    var dict : Dictionary<Int, Array<String>> = [:]
    
    dict[1] = ["1A", "1D"]
    dict[2] = ["1A", "2D"]
    dict[3] = ["1A", "3D"]
    
    dict[5] = ["4A", "4D"]
    dict[6] = ["4A", "1D"]
    dict[7] = ["4A", "2D"]
    dict[8] = ["4A", "3D"]
    dict[9] = ["4A", "5D"]
    
    dict[10] = ["6A", "4D"]
    dict[11] = ["6A", "1D"]
    dict[12] = ["6A", "2D"]
    dict[13] = ["6A", "3D"]
    dict[14] = ["6A", "5D"]
    
    dict[15] = ["7A", "4D"]
    dict[16] = ["7A", "1D"]
    dict[17] = ["7A", "2D"]
    dict[18] = ["7A", "3D"]
    dict[19] = ["7A", "5D"]
    
    dict[21] = ["8A", "1D"]
    dict[22] = ["8A", "2D"]
    dict[23] = ["8A", "3D"]
    
    
    crossword.clueToTagsMap = [:]
    for (tag, clues) in dict {
        for clue in clues {
            if (crossword.clueToTagsMap?[clue] == nil) {
                crossword.clueToTagsMap?[clue] = []
            }
            crossword.clueToTagsMap?[clue]!.append(tag)
            
        }
    }
    crossword.tagToCluesMap = dict
}
