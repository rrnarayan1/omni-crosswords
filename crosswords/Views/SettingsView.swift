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
import Firebase
import FirebaseAuth

let allSubscriptions: Array<String> = ["LA Times", "The Atlantic", "Newsday", "New Yorker", "USA Today", "Wall Street Journal"]

struct SettingsView: View {
    
    @ObservedObject var userSettings = UserSettings()
    @State var showSubscriptions = false
    @State var showKeyboardShortcuts = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Toggle(isOn: $userSettings.showSolved) {
                    Text("Show solved puzzles in list")
                }.frame(width: 300)
                
                Toggle(isOn: $userSettings.skipCompletedCells) {
                    Text("Skip completed cells")
                }.frame(width: 300)
                
                Toggle(isOn: $userSettings.defaultErrorTracking) {
                    Text("Error tracking on by default")
                }.frame(width: 300)
                
                Toggle(isOn: $userSettings.showTimer) {
                    Text("Show timer")
                }.frame(width: 300)
                
                DeletionPickerView()
                
                Button(action: {
                    self.showSubscriptions.toggle()
                }) {
                    Text("Configure Puzzle Subscriptions")
                }
                .sheet(isPresented: $showSubscriptions) {
                    SubscriptionsView()
                }
                
                Button(action: {
                    self.showKeyboardShortcuts.toggle()
                }) {
                    Text("View Keyboard Shortcuts")
                }
                .sheet(isPresented: $showKeyboardShortcuts) {
                    KeyboardShortcutsView()
                }.padding(.top, 20)
                Spacer()
            }
            .navigationBarTitle("Settings", displayMode: .large)
            .navigationBarColor(.systemGray6)
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
            .navigationBarTitle("Crossword Settings", displayMode: .large)
            .navigationBarColor(.systemGray6)
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

struct KeyboardShortcutsView: View {
    
    var body: some View {
        VStack {
            HStack {
                Text("Go left one cell: ")
                Spacer()
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowLeft, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
            }
            HStack {
                Text("Go right one cell: ")
                Spacer()
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowRight, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
            }
            HStack {
                Text("Go up one cell: ")
                Spacer()
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowUp, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
            }
            HStack {
                Text("Go down one cell: ")
                Spacer()
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowDown, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
            }
            HStack {
                Text("Go to next clue: ")
                Spacer()
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowAltCircleUp, style: FontAwesomeStyle.regular, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
                Image(uiImage:UIImage.fontAwesomeIcon(name: .plus, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 15, height: 15)))
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowRight, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
                
            }
            HStack {
                Text("Go to previous clue: ")
                Spacer()
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowAltCircleUp, style: FontAwesomeStyle.regular, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
                Image(uiImage:UIImage.fontAwesomeIcon(name: .plus, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 15, height: 15)))
                Image(uiImage:UIImage.fontAwesomeIcon(name: .arrowLeft, style: FontAwesomeStyle.solid, textColor: UIColor.systemGray, size: CGSize(width: 30, height: 30)))
                
            }
        }
        .frame(width: 200)
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
            .navigationBarTitle("Subscriptions", displayMode: .large)
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
    
    @Published var showTimer: Bool {
        didSet {
            UserDefaults.standard.set(showTimer, forKey: "showTimer")
        }
    }
    
    @Published var user: User?
    
    init() {
        self.showSolved = UserDefaults.standard.object(forKey: "showSolved") as? Bool ?? true
        self.skipCompletedCells = UserDefaults.standard.object(forKey: "skipCompletedCells") as? Bool ?? true
        self.defaultErrorTracking = UserDefaults.standard.object(forKey: "defaultErrorTracking") as? Bool ?? false
        self.daysToWaitBeforeDeleting = UserDefaults.standard.object(forKey: "daysToWaitBeforeDeleting") as? String ?? "14"
        self.subscriptions = UserDefaults.standard.object(forKey: "subscriptions") as? Array<String> ?? allSubscriptions
        self.user = Auth.auth().currentUser
        self.showTimer = UserDefaults.standard.object(forKey: "showTimer") as? Bool ?? true
    }
}
