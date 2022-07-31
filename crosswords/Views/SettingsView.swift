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
import GameKit

let allSubscriptions: Array<String> = ["LA Times", "The Atlantic", "Newsday", "New Yorker", "USA Today", "Wall Street Journal"]

struct SettingsView: View {
    @ObservedObject var userSettings = UserSettings()
    @State var showSubscriptions = false
    @State var showKeyboardShortcuts = false

    var body: some View {
        VStack(alignment: .leading) {
            TogglesSettingsView()

            PickerViews()

            GameCenterLoginView()

            NavigationLink(
                destination: SubscriptionsView(),
                label: {Text("Configure Puzzle Subscriptions")}
            ).padding(.top, 20)

            Spacer()
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 400))
        .navigationBarTitle("Settings")
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarColor(.systemGray6)
        .navigationBarItems(trailing:
            HStack {
                Link(destination: URL(string: "https://rrnarayan1.github.io/omni-crosswords/#four")!) {
                    Image(systemName: "questionmark.circle")
                }
            }
        )
        .padding(30)
    }
}

struct TogglesSettingsView: View {
    @ObservedObject var userSettings = UserSettings()

    var body: some View {
        Toggle(isOn: $userSettings.showSolved) {
            Text("Show solved puzzles in list")
        }

        Toggle(isOn: $userSettings.skipCompletedCells) {
            Text("Skip completed cells")
        }
        .onChange(of: userSettings.skipCompletedCells, perform: {newSkipCompletedCells in
            if(!newSkipCompletedCells) {
                userSettings.loopBackInsideUncompletedWord = false
            }
        })

        Toggle(isOn: $userSettings.loopBackInsideUncompletedWord) {
            Text("Loop Back Inside Uncompleted Word")
        }.disabled(!userSettings.skipCompletedCells)

        Toggle(isOn: $userSettings.defaultErrorTracking) {
            Text("Error tracking on by default")
        }

        Toggle(isOn: $userSettings.showTimer) {
            Text("Show timer")
        }

        Toggle(isOn: $userSettings.spaceTogglesDirection) {
            Text("Space bar toggles direction")
        }

        Toggle(isOn: $userSettings.enableHapticFeedback) {
            Text("Enable haptic feedback")
        }
    }
}

struct GameCenterLoginView: View {
    @ObservedObject var userSettings = UserSettings()

    func authenticateUser() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { vc, error in
            guard error == nil else {
                userSettings.shouldTryGameCenterLogin = false
                print(error?.localizedDescription ?? "")
                return
            }
            userSettings.gameCenterPlayer = localPlayer
        }
    }

    var body: some View {
        Toggle(isOn: $userSettings.shouldTryGameCenterLogin) {
            Text("Game Center Sync (BETA) (Turn this on on all devices)")
        }
        .onChange(of: userSettings.shouldTryGameCenterLogin, perform: { shouldTryLogin in
            if (shouldTryLogin) {
                authenticateUser()
            }
        })
    }
}

struct PickerViews: View {
    @ObservedObject var userSettings = UserSettings()
    @AppStorage("selectedAppearance") var selectedAppearance = 0
    
    var body: some View {
        VStack {
            Picker("Color Scheme Override", selection: $selectedAppearance) {
                Text("System Default").tag(0)
                Text("Light Mode").tag(1)
                Text("Dark Mode").tag(2)
            }.onChange(of: selectedAppearance, perform: { value in
                ColorSchemeUtil().overrideDisplayMode()
            })
            .pickerStyle(.segmented)

            HStack {
                Text("Automatically delete puzzles after:")
                Spacer()
                Picker(userSettings.daysToWaitBeforeDeleting + " days", selection: $userSettings.daysToWaitBeforeDeleting) {
                    ForEach((3..<22)) { flavor in
                        Text(String(flavor)+" days").tag(String(flavor))
                    }
                    Text("Never (May cause issues with performance)").tag("Never")
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Clue Font Size:")
                Spacer()
                Picker(String(userSettings.clueSize) + " pt", selection: $userSettings.clueSize) {
                    ForEach((13..<21)) { flavor in
                        Text(String(flavor)+" pt").tag(Int(flavor))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

struct SubscriptionsView: View {
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
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
    
    @Published var spaceTogglesDirection: Bool {
        didSet {
            UserDefaults.standard.set(spaceTogglesDirection, forKey: "spaceTogglesDirection")
        }
    }
    
    @Published var enableHapticFeedback: Bool {
        didSet {
            UserDefaults.standard.set(enableHapticFeedback, forKey: "enableHapticFeedback")
        }
    }
    
    @Published var shouldTryGameCenterLogin: Bool {
        didSet {
            UserDefaults.standard.set(shouldTryGameCenterLogin, forKey: "shouldTryGameCenterLogin")
        }
    }
    
    @Published var lastAlertId: Int {
        didSet {
            UserDefaults.standard.set(lastAlertId, forKey: "lastAlertId")
        }
    }
    
    @Published var loopBackInsideUncompletedWord: Bool {
        didSet {
            UserDefaults.standard.set(loopBackInsideUncompletedWord, forKey: "loopBackInsideUncompletedWord")
        }
    }
    
    @Published var clueSize: Int {
        didSet {
            UserDefaults.standard.set(clueSize, forKey: "clueSize")
        }
    }
    
    @Published var user: User?
    @Published var gameCenterPlayer: GKLocalPlayer?
    
    init() {
        self.showSolved = UserDefaults.standard.object(forKey: "showSolved") as? Bool ?? true
        self.skipCompletedCells = UserDefaults.standard.object(forKey: "skipCompletedCells") as? Bool ?? true
        self.defaultErrorTracking = UserDefaults.standard.object(forKey: "defaultErrorTracking") as? Bool ?? false
        self.daysToWaitBeforeDeleting = UserDefaults.standard.object(forKey: "daysToWaitBeforeDeleting") as? String ?? "14"
        self.subscriptions = UserDefaults.standard.object(forKey: "subscriptions") as? Array<String> ?? allSubscriptions
        self.user = Auth.auth().currentUser
        self.showTimer = UserDefaults.standard.object(forKey: "showTimer") as? Bool ?? true
        self.spaceTogglesDirection = UserDefaults.standard.object(forKey: "spaceTogglesDirection") as? Bool ?? false
        self.enableHapticFeedback = UserDefaults.standard.object(forKey: "enableHapticFeedback") as? Bool ?? true
        self.shouldTryGameCenterLogin = UserDefaults.standard.bool(forKey: "shouldTryGameCenterLogin")
        self.lastAlertId = UserDefaults.standard.integer(forKey: "lastAlertId")
        self.loopBackInsideUncompletedWord = UserDefaults.standard.bool(forKey: "loopBackInsideUncompletedWord")
        self.gameCenterPlayer = GKLocalPlayer.local
        self.clueSize = UserDefaults.standard.object(forKey: "clueSize") as? Int ?? 13
        self.gameCenterPlayer?.register(GameCenterListener())
    }
}
