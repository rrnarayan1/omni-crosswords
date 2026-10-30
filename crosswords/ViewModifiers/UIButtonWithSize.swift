//
//  CustomUIButton.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/23/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import UIKit

struct UIButtonWithSize {
    var button: UIButton
    var width: CGFloat = Constants.keyboardToolbarIconSize
    var isHidden: Bool = false

    func getWidth() -> CGFloat {
        return isHidden ? 0.0 : width
    }
}
