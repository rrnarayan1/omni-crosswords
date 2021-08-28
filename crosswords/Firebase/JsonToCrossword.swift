//
//  FirebaseToCrossword.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/29/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

func jsonToCrossword(crossword: Crossword, data: DocumentSnapshot) -> Void {
    crossword.length = data.get("width") as! Int16
    crossword.height = data.get("height") as! Int16
    crossword.author = data.get("author") as? String
    crossword.notes = data.get("notes") as? String
    crossword.copyright = data.get("copyright") as? String
    crossword.outletName = data.get("crossword_outlet_name") as? String
    crossword.title = data.get("title") as? String
    crossword.date = (data.get("date") as! Timestamp).dateValue()
    crossword.id = data.documentID
    crossword.clues = data.get("clues") as? Dictionary<String, String>
    crossword.solution = data.get("solution") as? Array<String>
    let symbols = data.get("symbols") as? Array<Int>
    crossword.symbols = symbols
    let tagToCluesList = data.get("tag_to_clue_map") as? Array<Dictionary<String, String>>
    crossword.tagToCluesMap = tagToCluesList
    crossword.solved = false
    crossword.addedTime = Date().timeIntervalSince1970
    
    
    crossword.clueToTagsMap = [:]
    for tag in 0..<tagToCluesList!.count {
        for dir in ["A", "D"] {
            if (tagToCluesList![tag].count > 0 ) {
                let clue = tagToCluesList![tag][dir]!
                if crossword.clueToTagsMap?[clue] == nil {
                    crossword.clueToTagsMap?[clue] = []
                }
                crossword.clueToTagsMap?[clue]!.append(tag)
            }
        }
    }
    crossword.entry = Array(repeating: "", count: symbols!.count)
    for i in 0..<symbols!.count {
        if (symbols![i] == -1) {
            crossword.entry![i] = "."
        }
    }
    
}
