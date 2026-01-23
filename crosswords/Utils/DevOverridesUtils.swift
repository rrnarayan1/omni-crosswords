//
//  DevOverridesUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/23/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import Foundation

struct DevOverridesUtils {
    static func getLocalMode() -> Bool {
        if let devOverridesPath = Bundle.main.path(forResource: "DevOverrides", ofType: "plist") {
            // If your plist contain root as Dictionary
            if let devOverrides = NSDictionary(contentsOfFile: devOverridesPath) as? [String: Bool] {
                return devOverrides["localMode"] ?? false
            }
        }
        return false
    }
}
