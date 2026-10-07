//
//  UIBarButtonItem+Extensions.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/20/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//
import SwiftUI

extension UIBarButtonItem {

    func hideSharedBackgroundIfAvailable() -> some UIBarButtonItem {
        if #available(iOS 26.0, *) {
            self.hidesSharedBackground = true
            if #available(iOS 27.0, *) {
                self.isPaddingRemoved = true
            }
            return self
        } else {
            return self
        }
    }
}
