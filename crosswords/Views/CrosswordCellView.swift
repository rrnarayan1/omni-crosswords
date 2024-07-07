//
//  CrosswordCellView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/23/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordCellView: View, Equatable {

    var value: String
    var correctValue: String
    var symbol: Int
    var tag: Int
    var onTap: (Int) -> Void
    var onLongPress: (Int) -> Void
    var boxWidth: CGFloat
    var isErrorTrackingEnabled: Bool
    var isFocused: Bool
    var isHighlighted: Bool
    var isSolutionAvailable: Bool
    @Environment(\.colorScheme) var colorScheme
    
    static func == (lhs: CrosswordCellView, rhs: CrosswordCellView) -> Bool {
        if (lhs.tag != rhs.tag) {
            return false
        }
        if ((lhs.value != rhs.value) || (lhs.isFocused != rhs.isFocused) || (lhs.isHighlighted != rhs.isHighlighted)
            || (lhs.isErrorTrackingEnabled != rhs.isErrorTrackingEnabled) || (lhs.boxWidth != rhs.boxWidth)) {
            return false
        }
        return true
    }
    
    var body: some View {
        return ZStack() {
            Color.init(getBackgroundColor())
            HStack(alignment: .center) {
                if (isEditable()) {
                    Text(value)
                        .font(.system(size: 70*boxWidth/100))
                        .frame(alignment: .center)
                }
            }
            if symbol >= 1000 {
                Circle()
                    .stroke(lineWidth: 0.5)
            }
        }
        .overlay(
            Text(symbol % 1000 > 0 ? String(symbol % 1000) : "")
                .font(.system(size: boxWidth/4))
                .padding(boxWidth/30),
            alignment: .topLeading
        )
        .onTapGesture {
            onTap(tag)
        }
        .border(.black, width: 0.25)
        .contentShape(Rectangle())
//        .contextMenu {
//            if (isSolutionAvailable) {
//                Button(action: {
//                    onLongPress(tag)
//                }) {
//                    Text("Solve Square")
//                }
//            }
//        }
    }
    
    func getBackgroundColor() -> UIColor {
        if (!isEditable()) {
            return UIColor.black
        } else if (isErrorTrackingEnabled) {
            if (value != "" && value != correctValue) {
                if (isHighlighted) {
                    if (isFocused) {
                        return UIColor.systemRed.withAlphaComponent(0.6)
                    } else {
                        return UIColor.systemRed.withAlphaComponent(0.5)
                    }
                } else {
                    return UIColor.systemRed.withAlphaComponent(0.4)
                }
            }
        }
        
        if isHighlighted {
            if (colorScheme == .dark) {
                if (isFocused) {
                    return UIColor.systemBlue.withAlphaComponent(0.8)
                } else {
                    return UIColor.systemBlue.withAlphaComponent(0.5)
                }
            } else {
                if (isFocused) {
                    return UIColor.systemBlue.withAlphaComponent(0.6)
                } else {
                    return UIColor.systemBlue.withAlphaComponent(0.2)
                }
            }
        } else {
            return colorScheme == .dark ? UIColor.systemGray2 : UIColor.systemBackground
        }
    }
    
    func isEditable() -> Bool {
        return value != "."
    }
}
