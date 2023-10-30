//
//  NavigationLazyView.swift
//  crosswords
//
//  Created by Rohan Narayan on 10/29/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import Foundation
import SwiftUI

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
