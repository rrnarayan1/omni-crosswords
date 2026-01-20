//
//  ToolbarContent+Extensions.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/20/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//
import SwiftUI

extension ToolbarContent {

    @ToolbarContentBuilder
    func hideSharedBackgroundIfAvailable() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
