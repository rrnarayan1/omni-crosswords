//
//  SettingsView.swift
//  crosswords
//
//  Created by Rohan Narayan on 8/7/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import Combine
import FontAwesome_swift

let allSubscriptions: Array<String> = ["LA Times", "The Atlantic", "Newsday", "New Yorker", "USA Today", "Wall Street Journal"]

struct SettingsView: View {
    
    @ObservedObject var userSettings = UserSettings()
    @State var showSubscriptions = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Toggle(isOn: $userSettings.showSolved) {
                    Text("Show solved puzzles in list")
                }.frame(width: 300)
                
                Toggle(isOn: $userSettings.skipCompletedCells) {
                    Text("Skip Completed Cells")
                }.frame(width: 300)
                
                Toggle(isOn: $userSettings.defaultErrorTracking) {
                    Text("Error Tracking on By Default")
                }.frame(width: 300)
                
                DeletionPickerView()
                
                Button(action: {
                    print(allSubscriptions)
                    self.showSubscriptions.toggle()
                }) {
                    Text("Configure Puzzle Subscriptions")
                }
                .sheet(isPresented: $showSubscriptions) {
                    SubscriptionsView()
                }
                Spacer()
            }
            .navigationBarTitle("Settings")
            .padding(30)
        }
    }
}

struct CrosswordSettingsView: View {
    @Binding var errorTracking: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Toggle(isOn: $errorTracking) {
                    Text("Error Tracking")
                }.frame(width: 200)
                Spacer()
            }
            .navigationBarTitle("Crossword Settings")
            .padding(30)
        }
    }
    
}

struct DeletionPickerView: View {
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
        HStack {
            Text("Automatically delete puzzles after: ")
                .frame(width: 200)
            Picker("", selection: $userSettings.daysToWaitBeforeDeleting) {
                ForEach((3..<22)) { flavor in
                    Text(String(flavor)+" days").tag(String(flavor))
                }
                Text("Never").tag("Never")
            }
            .frame(width: 150)
            .clipped()
        }
    }
}

struct SubscriptionsView: View {
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ForEach((0..<allSubscriptions.count), id: \.self) { i in
                    HStack {
                        Text(allSubscriptions[i])
                        Spacer()
                        Button(action: {self.toggleSubscription(allSubscriptions[i])}) {
                            Image(uiImage: self.hasSub(allSubscriptions[i]) ? UIImage.fontAwesomeIcon(name: .checkSquare, style: FontAwesomeStyle.regular, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)) : UIImage.fontAwesomeIcon(name: .square, style: FontAwesomeStyle.regular, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
                        }
                    }
                }
            }
            .navigationBarTitle("Subscriptions")
            .padding(30)
        }
    }
    
    func toggleSubscription(_ sub: String) -> Void {
        let index = userSettings.subscriptions.lastIndex(of: sub)
        if (index == nil) {
            userSettings.subscriptions.append(sub)
        } else {
            userSettings.subscriptions.remove(at: index!)
        }
    }
    
    func hasSub(_ sub : String) -> Bool {
        return userSettings.subscriptions.contains(sub)
    }
}

class UserSettings: ObservableObject {
    @Published var showSolved: Bool {
        didSet {
            UserDefaults.standard.set(showSolved, forKey: "showSolved")
        }
    }
    
    @Published var daysToWaitBeforeDeleting: String {
        didSet {
            UserDefaults.standard.set(daysToWaitBeforeDeleting, forKey: "daysToWaitBeforeDeleting")
        }
    }
    
    @Published var subscriptions: Array<String> {
        didSet {
            UserDefaults.standard.set(subscriptions, forKey: "subscriptions")
        }
    }
    
    @Published var skipCompletedCells: Bool {
        didSet {
            UserDefaults.standard.set(skipCompletedCells, forKey: "skipCompletedCells")
        }
    }
    
    @Published var defaultErrorTracking: Bool {
        didSet {
            UserDefaults.standard.set(defaultErrorTracking, forKey: "defaultErrorTracking")
        }
    }
    
    init() {
        self.showSolved = UserDefaults.standard.object(forKey: "showSolved") as? Bool ?? true
        self.skipCompletedCells = UserDefaults.standard.object(forKey: "skipCompletedCells") as? Bool ?? true
        self.defaultErrorTracking = UserDefaults.standard.object(forKey: "defaultErrorTracking") as? Bool ?? false
        self.daysToWaitBeforeDeleting = UserDefaults.standard.object(forKey: "daysToWaitBeforeDeleting") as? String ?? "14"
        self.subscriptions = UserDefaults.standard.object(forKey: "subscriptions") as? Array<String> ?? allSubscriptions
    }
}
