//
//  ShapeStyle+Extensions.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/10/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//
import SwiftUI

extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
