//
//  SettingsView.swift
//  crosswords
//
//  Created by Rohan Narayan on 8/7/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var userSettings: UserSettings
    @State var showSubscriptions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TogglesSettingsView(userSettings: self.userSettings)

                PickerViews(userSettings: self.userSettings)

                GameCenterLoginView(userSettings: self.userSettings)

                Button("Configure Puzzle Subscriptions"){
                    self.showSubscriptions.toggle()
                }
                .padding(.top)
                .buttonStyle(.bordered)
                .navigationDestination(isPresented: self.$showSubscriptions) {
                    SubscriptionsView(userSettings: self.userSettings)
                }
            }
            .padding(.trailing, 10)
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 450))
        .navigationBarTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Link(destination: URL(string: "https://ko-fi.com/rrnarayan1")!) {
                        Image(systemName: "hands.clap.fill")
                    }
                    Link(destination: URL(string: "https://omnicrosswords.app")!) {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
        }
    }
}

struct TogglesSettingsView: View {
    @ObservedObject var userSettings: UserSettings

    var body: some View {
        Toggle(isOn: $userSettings.showSolved) {
            Text("Show solved puzzles in list")
        }

        Toggle(isOn: $userSettings.skipCompletedCells) {
            Text("Skip completed cells")
        }
        .onChange(of: userSettings.skipCompletedCells) {_, newSkipCompletedCells in
            // if they don't want to skip completed cells anymore, looping back must be set to false
            if (!newSkipCompletedCells) {
                userSettings.loopBackInsideUncompletedWord = false
            }
        }

        Toggle(isOn: $userSettings.loopBackInsideUncompletedWord) {
            Text("Loop back inside uncompleted word")
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
        
        Toggle(isOn: $userSettings.useEmailAddressKeyboard) {
            Text("Use alternate keyboard type")
        }
    }
}

struct PickerViews: View {
    @ObservedObject var userSettings: UserSettings
    @AppStorage("selectedAppearance") var selectedAppearance = 0
    
    var body: some View {
        VStack {
            Picker("Color scheme override", selection: $selectedAppearance) {
                Text("System Default").tag(0)
                Text("Light Mode").tag(1)
                Text("Dark Mode").tag(2)
            }.onChange(of: selectedAppearance) {
                ColorSchemeUtil().overrideDisplayMode()
            }
            .pickerStyle(.segmented)
            
            HStack {
                Text("Clue cycle control placement")
                Spacer()
                Picker("Clue cycle control placement", selection: $userSettings.clueCyclePlacement) {
                    Text("Left").tag(0)
                    Text("Split").tag(1)
                    Text("Right").tag(2)
                }
                .pickerStyle(.menu)
            }
            
            HStack {
                Text("Auto-delete puzzles after")
                Spacer()
                Picker("Auto-delete puzzles after", selection: $userSettings.daysToWaitBeforeDeleting) {
                    ForEach((3..<22)) { i in
                        Text(String(i)+" days").tag(String(i))
                    }
                    Text("Never (May cause issues with performance)").tag("Never")
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Clue font size")
                Spacer()
                Picker("Clue font size", selection: $userSettings.clueSize) {
                    ForEach((13..<21)) { flavor in
                        Text(String(flavor)+" pt").tag(Int(flavor))
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Zoom magnification level")
                Spacer()
                Picker("Zoom magnification level", selection: $userSettings.zoomMagnificationLevel) {
                    Text("1.25x").tag(Float(1.25))
                    Text("1.5x").tag(Float(1.5))
                    Text("2x").tag(Float(2.0))
                    Text("2.5x").tag(Float(2.5))
                }
                .pickerStyle(.menu)
            }
        }
    }
}

struct GameCenterLoginView: View {
    @ObservedObject var userSettings: UserSettings

    @State var showGameCenterDiagnostics: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: self.$userSettings.shouldTryGameCenterLogin) {
                Text("Game Center Sync")
            }
            .onChange(of: self.userSettings.shouldTryGameCenterLogin) { _, shouldTryLogin in
                if (shouldTryLogin) {
                    GameCenterUtils.maybeAuthenticate(userSettings: self.userSettings)
                }
            }

            if (self.userSettings.shouldTryGameCenterLogin) {
                Button("Game Center Diagnostics") {
                    self.showGameCenterDiagnostics.toggle()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationDestination(isPresented: self.$showGameCenterDiagnostics) {
            GameCenterDiagnosticsView(userSettings: self.userSettings)
        }
    }
}

struct SubscriptionsView: View {
    @ObservedObject var userSettings: UserSettings

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Constants.allSubscriptions, id: \.self) { subscription in
                HStack {
                    Text(subscription)
                    Spacer()
                    Button(action: {self.toggleSubscription(subscription)}) {
                        Image(systemName: self.hasSub(subscription)
                              ? "checkmark.square" : "square")
                            .foregroundColor(Color(UIColor.systemGray))
                            .font(.system(size: 18))
                    }
                }
                .padding(5)
            }
        }
        .navigationBarTitle("Subscriptions", displayMode: .inline)
        .padding(30)
    }
    
    func toggleSubscription(_ sub: String) -> Void {
        let index = self.userSettings.subscriptions.lastIndex(of: sub)
        if (index == nil) {
            self.userSettings.subscriptions.append(sub)
        } else {
            self.userSettings.subscriptions.remove(at: index!)
        }
    }
    
    func hasSub(_ sub : String) -> Bool {
        return self.userSettings.subscriptions.contains(sub)
    }
}

struct GameCenterDiagnosticsView: View {
    @ObservedObject var userSettings: UserSettings
    @State var fetchGamesError: String?

    var body: some View {
        VStack {
            Text("Ensure that the setting is enabled on all devices")
                .padding(.bottom)
            let shouldTryGameCenter = self.userSettings.shouldTryGameCenterLogin
            Text("Setting Enabled: \(shouldTryGameCenter ? "YES" : "NO")")
                .foregroundStyle(shouldTryGameCenter ? .green : .red)

            if (shouldTryGameCenter) {
                let isAuthenticated = GameCenterUtils.isAuthenticated()
                Text("Game Center Authenticated: \(isAuthenticated ? "YES" : "NO")")
                    .foregroundStyle(isAuthenticated ? .green : .red)

                if (isAuthenticated) {
                    Text("Fetch Game Center Games: \(self.fetchGamesError ?? "GOOD")")
                        .foregroundStyle(self.fetchGamesError == nil ? .green : .red)
                }
            }
        }
        .onAppear {
            GameCenterUtils.fetchGames(userSettings: self.userSettings,
                                       completionHandler: {_ in self.fetchGamesError = nil},
                                       errorHandler: {error in
                                            self.fetchGamesError = error.localizedDescription
                                       })
        }
        .navigationTitle("Game Center Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
