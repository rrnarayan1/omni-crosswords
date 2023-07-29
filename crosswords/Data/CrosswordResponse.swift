//
//  CrosswordResponse.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/26/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import Foundation

struct CrosswordResponse: Decodable {
    let crossword_outlet_name: String
    let date: Int
    let author: String
    let title: String
    let width: Int
    let height: Int
    let copyright: String
    let notes: String
    let solution: Array<String>
    let clues: Dictionary<String, String>
    let tag_to_clue_map: Array<Dictionary<String, String>>
    let symbols: Array<Int>
}
