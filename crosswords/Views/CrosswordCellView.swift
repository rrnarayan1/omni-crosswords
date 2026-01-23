//
//  CrosswordCellView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/23/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordCellView: View, Equatable {
    @Environment(\.colorScheme) var colorScheme

    var value: String
    var correctValue: String
    var symbol: Int
    var tag: Int
    var onTap: (Int) -> Void
    var boxWidth: CGFloat
    var isErrorTrackingEnabled: Bool
    var isFocused: Bool
    var isHighlighted: Bool

    static func == (lhs: CrosswordCellView, rhs: CrosswordCellView) -> Bool {
        if (lhs.tag != rhs.tag) {
            return false
        }
        if ((lhs.value != rhs.value) || (lhs.isFocused != rhs.isFocused)
            || (lhs.isHighlighted != rhs.isHighlighted)
            || (lhs.isErrorTrackingEnabled != rhs.isErrorTrackingEnabled)
            || (lhs.boxWidth != rhs.boxWidth)) {
            return false
        }
        return true
    }

    var body: some View {
        return ZStack(alignment: .center) {
            Color.init(self.getBackgroundColor())
            if (self.isEditable()) {
                Text(self.value)
                    .font(.system(size: self.getFontSize()))
                    .padding(self.boxWidth/30)
            }
            if (self.symbol >= 1000 && self.symbol < 10000) {
                // 1000 means cell should be circled,
                // 10000 means cell should be shaded
                Circle()
                    .stroke(lineWidth: 0.5)
            }
        }
        .overlay(
            // clue number
            Text(self.symbol % 1000 > 0 ? String(self.symbol % 1000) : "")
                .font(.system(size: self.boxWidth/4))
                .padding(self.boxWidth/30),
            alignment: .topLeading
        )
        .onTapGesture {
            self.onTap(self.tag)
        }
        .border(.black, width: 0.25)
        .contentShape(Rectangle())
    }

    func getFontSize() -> CGFloat {
        if (self.value.count == 1) {
            return 0.7*self.boxWidth
        }
        return (self.boxWidth) / CGFloat(self.value.count)
    }

    func getBackgroundColor() -> UIColor {
        if (!self.isEditable()) {
            // Block cell
            return UIColor.black
        } else if (self.isErrorTrackingEnabled && self.value != "" && self.value != self.correctValue) {
            // Error tracking is enabled and cell is incorrect
            if (self.isHighlighted) {
                if (self.isFocused) {
                    return UIColor.systemRed.withAlphaComponent(0.6)
                } else {
                    return UIColor.systemRed.withAlphaComponent(0.5)
                }
            } else {
                return UIColor.systemRed.withAlphaComponent(0.4)
            }
        } else if (self.isHighlighted) {
            // Highlighted cell
            if (self.colorScheme == .dark) {
                if (self.isFocused) {
                    return UIColor.systemBlue.withAlphaComponent(0.8)
                } else {
                    return UIColor.systemBlue.withAlphaComponent(0.5)
                }
            } else {
                if (self.isFocused) {
                    return UIColor.systemBlue.withAlphaComponent(0.6)
                } else {
                    return UIColor.systemBlue.withAlphaComponent(0.2)
                }
            }
        } else if (self.symbol >= 10000) {
            // signifies shaded cells
            return UIColor.gray
        } else {
            return self.colorScheme == .dark ? UIColor.systemGray2 : UIColor.systemBackground
        }
    }

    func isEditable() -> Bool {
        return self.value != "."
    }
}
