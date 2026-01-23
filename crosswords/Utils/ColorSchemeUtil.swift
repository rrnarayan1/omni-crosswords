//
//  ColorSchemeUtil.swift
//  crosswords
//
//  Created by Rohan Narayan on 2/16/22.
//  Copyright © 2022 Rohan Narayan. All rights reserved.
//

import SwiftUI

class ColorSchemeUtil {
    @AppStorage("selectedAppearance") var selectedAppearance = 0

    func overrideDisplayMode() {
        var userInterfaceStyle: UIUserInterfaceStyle

        switch (self.selectedAppearance) {
        case 2:
            userInterfaceStyle = .dark
        case 1:
            userInterfaceStyle = .light
        default:
            userInterfaceStyle = .unspecified
        }
        
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.overrideUserInterfaceStyle = userInterfaceStyle
    }
}
