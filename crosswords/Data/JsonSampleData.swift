//
//  JsonSampleData.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/24/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import Foundation

struct JsonSampleData: Decodable {
    let id: String
    let notes: String
    let clues: [String: String]
    let crossword_outlet_name: String
    let symbols: [Int]
    let tag_to_clue_map: [[String: String]]
    let title: String
    let author: String
    let height: Int
    let width: Int
    let date: Int64
    let copyright: String
    let solution: [String]
}
