//
//  Collections+Extensions.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/24/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

extension Collection {
    subscript(safe index: Index) -> Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
}
