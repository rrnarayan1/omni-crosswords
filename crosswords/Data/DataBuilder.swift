//
//  DataBuilder.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/24/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import Foundation

struct JSONData: Decodable {
    let id: String
    let notes: String
    let clues: Dictionary<String, String>
    let crossword_outlet_name: String
    let symbols: Array<Int>
    let tag_to_clue_map: Array<Dictionary<String, String>>
    let title: String
    let author: String
    let height: Int
    let width: Int
    let date: Int64
    let copyright: String
    let solution: Array<String>
}


func buildSampleCrossword(crossword: Crossword) -> Void {
    if let url = Bundle.main.url(forResource: "sampleData", withExtension: "json"),
       let data = try? Data(contentsOf: url) {
        let decoder = JSONDecoder()
        do {
            let jsonData = try decoder.decode(JSONData.self, from: data)

            crossword.length = Int16(jsonData.width)
            crossword.height = Int16(jsonData.height)
            crossword.author = jsonData.author
            crossword.notes = jsonData.notes
            crossword.copyright = jsonData.copyright
            crossword.outletName = jsonData.crossword_outlet_name
            crossword.title = jsonData.title
            crossword.date = Date(timeIntervalSince1970: TimeInterval(jsonData.date))
            crossword.id = jsonData.id
            crossword.clues = jsonData.clues
            crossword.solution = jsonData.solution
            let symbols = jsonData.symbols
            crossword.symbols = symbols
            let tagToCluesList = jsonData.tag_to_clue_map
            crossword.tagToCluesMap = tagToCluesList
            crossword.solved = false
            crossword.isHidden = false
            crossword.addedTime = Date().timeIntervalSince1970
            crossword.versionId = 0

            crossword.clueToTagsMap = [:]
            for tag in 0..<tagToCluesList.count {
                for dir in ["A", "D"] {
                    if (tagToCluesList[tag].count > 0 ) {
                        let clue = tagToCluesList[tag][dir]!
                        if crossword.clueToTagsMap?[clue] == nil {
                            crossword.clueToTagsMap?[clue] = []
                        }
                        crossword.clueToTagsMap?[clue]!.append(tag)
                    }
                }
            }
            crossword.entry = Array(repeating: "", count: symbols.count)
            for i in 0..<symbols.count {
                if (symbols[i] == -1) {
                    crossword.entry![i] = "."
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
