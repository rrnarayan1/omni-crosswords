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

struct Ramp: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start at Top Right
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        // Down to Bottom Left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Left to Bottom Right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Close back to top
        path.closeSubpath()

        return path
    }
}
