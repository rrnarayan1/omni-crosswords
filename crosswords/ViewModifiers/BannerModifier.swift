//
//  BannerModifier.swift
//  crosswords
//
//  Created by Rohan Narayan on 6/4/22.
//  Copyright © 2022 Rohan Narayan. All rights reserved.
//

import Foundation
import SwiftUI

struct BannerModifier: ViewModifier {
    
    struct BannerData {
        var bannerId: Int
        var title: String
        var detail: String

        init() {
            self.bannerId = 0
            self.title = ""
            self.detail = ""
        }
    }
    
    @Binding var data: BannerData
    @ObservedObject var userSettings: UserSettings

    func body(content: Content) -> some View {
        VStack {
            if (self.data.title != "") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(self.data.title)
                            .bold()
                        Text(self.data.detail)
                    }
                    Spacer()
                    Button(action: self.closeBanner) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 18))
                    }
                    
                }
                .foregroundColor(Color.white)
                .padding(12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            content
        }
    }
    
    func closeBanner() {
        self.data.title = ""
        self.userSettings.lastAlertId = self.data.bannerId
    }
}

extension View {
    func banner(data: Binding<BannerModifier.BannerData>, userSettings: UserSettings) -> some View {
        self.modifier(BannerModifier(data: data, userSettings: userSettings))
    }
}
