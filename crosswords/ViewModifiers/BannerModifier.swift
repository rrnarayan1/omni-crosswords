//
//  BannerModifier.swift
//  crosswords
//
//  Created by Rohan Narayan on 6/4/22.
//  Copyright © 2022 Rohan Narayan. All rights reserved.
//

import Foundation
import FontAwesome_swift
import SwiftUI

struct BannerModifier: ViewModifier {
    
    struct BannerData {
        var bannerId:Int
        var title:String
        var detail:String
    }
    
    @Binding var data:BannerData
    @ObservedObject var userSettings = UserSettings()
    
    func body(content: Content) -> some View {
        VStack {
            if data.title != "" {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.title)
                            .bold()
                        Text(data.detail)
                    }
                    Spacer()
                    Button(action: closeBanner) {
                        Text("X")
                            .font(.system(size: 20, design: .monospaced))
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
        data.title = ""
        userSettings.lastAlertId = data.bannerId
    }
}

extension View {
    func banner(data: Binding<BannerModifier.BannerData>) -> some View {
        self.modifier(BannerModifier(data: data))
    }
}
