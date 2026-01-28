//
//  DataUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/6/26.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class DataUtils {
    static func jsonToCrossword(crossword: Crossword, data: DocumentSnapshot) -> Void {
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
        crossword.isHidden = false
        crossword.addedTime = Date().timeIntervalSince1970
        crossword.versionId = data.get("version") == nil ? 0 : data.get("version") as! Int16


        crossword.clueToTagsMap = [:]
        for tag in 0..<tagToCluesList!.count {
            for dir in ["A", "D"] {
                if (tagToCluesList![tag].count > 0) {
                    let clue = tagToCluesList![tag][dir]
                    if let nnClue = clue {
                        if crossword.clueToTagsMap?[nnClue] == nil {
                            crossword.clueToTagsMap?[nnClue] = []
                        }
                        crossword.clueToTagsMap?[nnClue]!.append(tag)
                    }
                }
            }
        }
        crossword.entry = Array(repeating: "", count: symbols!.count)
        for i in 0..<symbols!.count {
            if (symbols![i] == -1) {
                crossword.entry![i] = "."
            }
        }
        crossword.helpTracking = Array(repeating: false, count: symbols!.count)
    }

    static func jsonToCrossword(crossword: Crossword, data: CrosswordResponse) -> Void {
        crossword.length = Int16(data.width)
        crossword.height = Int16(data.height)
        crossword.author = data.author
        crossword.notes = data.notes
        crossword.copyright = data.copyright
        crossword.outletName = data.crossword_outlet_name
        crossword.title = data.title
        crossword.date = NSDate(timeIntervalSince1970: TimeInterval(data.date)) as Date?
        crossword.id = data.crossword_outlet_name+String(data.solution.joined(separator: ",").hashValue)
        crossword.clues = data.clues
        crossword.solution = data.solution
        crossword.symbols = data.symbols
        let tagToCluesList = data.tag_to_clue_map
        crossword.tagToCluesMap = tagToCluesList
        crossword.solved = false
        crossword.isHidden = false
        crossword.addedTime = Date().timeIntervalSince1970
        crossword.versionId = 0


        crossword.clueToTagsMap = [:]
        for tag in 0..<tagToCluesList.count {
            for dir in ["A", "D"] {
                if (tagToCluesList[tag].count > 0) {
                    let clue = tagToCluesList[tag][dir]
                    if let nnClue = clue {
                        if crossword.clueToTagsMap?[nnClue] == nil {
                            crossword.clueToTagsMap?[nnClue] = []
                        }
                        crossword.clueToTagsMap?[nnClue]!.append(tag)
                    }
                }
            }
        }
        crossword.entry = Array(repeating: "", count: data.symbols.count)
        for i in 0..<data.symbols.count {
            if (data.symbols[i] == -1) {
                crossword.entry![i] = "."
            }
        }
        crossword.helpTracking = Array(repeating: false, count: data.symbols.count)
    }

    static func buildSampleCrossword(crossword: Crossword, resourceName: String) -> Void {
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            do {
                let jsonData = try decoder.decode(JsonSampleData.self, from: data)

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
                            let clue = tagToCluesList[tag][dir]
                            if let nnClue = clue {
                                if crossword.clueToTagsMap?[nnClue] == nil {
                                    crossword.clueToTagsMap?[nnClue] = []
                                }
                                crossword.clueToTagsMap?[nnClue]!.append(tag)
                            }
                        }
                    }
                }
                crossword.entry = Array(repeating: "", count: symbols.count)
                for i in 0..<symbols.count {
                    if (symbols[i] == -1) {
                        crossword.entry![i] = "."
                    }
                }
                crossword.helpTracking = Array(repeating: false, count: symbols.count)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    static func buildSolvedCrossword(solvedCrossword: SolvedCrossword, crossword: Crossword) -> Void {
        solvedCrossword.date = crossword.date
        solvedCrossword.id = crossword.id
        solvedCrossword.solveTime = crossword.solvedTime
        solvedCrossword.outletName = crossword.outletName
        solvedCrossword.numClues = Int32(crossword.clues!.count)
    }
}
