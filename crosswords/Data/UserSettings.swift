//
//  UserSettings.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/10/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//
import SwiftUI
import Firebase
import FirebaseAuth

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

    @Published var lastRefreshTime: Double {
        didSet {
            UserDefaults.standard.set(lastRefreshTime, forKey: "lastRefreshTime")
        }
    }

    @Published var useEmailAddressKeyboard: Bool {
        didSet {
            UserDefaults.standard.set(useEmailAddressKeyboard, forKey: "useEmailAddressKeyboard")
        }
    }

    @Published var clueCyclePlacement: Int {
        didSet {
            UserDefaults.standard.set(clueCyclePlacement, forKey: "clueCyclePlacement")
        }
    }

    @Published var zoomMagnificationLevel: Float {
        didSet {
            UserDefaults.standard.set(zoomMagnificationLevel, forKey: "zoomMagnificationLevel")
        }
    }

    @Published var user: User?
    @Published var useLocalMode: Bool

    init() {
        let useLocalMode = DevOverridesUtils.getLocalMode()
        self.useLocalMode = useLocalMode
        self.showSolved = UserDefaults.standard.object(forKey: "showSolved") as? Bool ?? true
        self.skipCompletedCells = UserDefaults.standard.object(forKey: "skipCompletedCells") as? Bool ?? true
        self.defaultErrorTracking = UserDefaults.standard.bool(forKey: "defaultErrorTracking")
        self.daysToWaitBeforeDeleting = UserDefaults.standard.object(
            forKey: "daysToWaitBeforeDeleting") as? String ?? "14"
        self.subscriptions = UserDefaults.standard.object(forKey: "subscriptions")
            as? Array<String> ?? Constants.allSubscriptions
        self.user = useLocalMode ? nil : Auth.auth().currentUser
        self.showTimer = UserDefaults.standard.object(forKey: "showTimer") as? Bool ?? true
        self.spaceTogglesDirection = UserDefaults.standard.bool(forKey: "spaceTogglesDirection")
        self.enableHapticFeedback = UserDefaults.standard.bool(forKey: "enableHapticFeedback")
        self.shouldTryGameCenterLogin = UserDefaults.standard.bool(forKey: "shouldTryGameCenterLogin")
        self.lastAlertId = UserDefaults.standard.integer(forKey: "lastAlertId")
        self.loopBackInsideUncompletedWord = UserDefaults.standard.bool(
            forKey: "loopBackInsideUncompletedWord")
        self.lastRefreshTime = UserDefaults.standard.double(forKey: "lastRefreshTime")
        self.clueSize = UserDefaults.standard.object(forKey: "clueSize") as? Int ?? 14
        self.useEmailAddressKeyboard = UserDefaults.standard.bool(forKey: "useEmailAddressKeyboard")
        self.clueCyclePlacement = UserDefaults.standard.integer(forKey: "clueCyclePlacement")
        self.zoomMagnificationLevel = UserDefaults.standard.object(forKey: "zoomMagnificationLevel")
            as? Float ?? 2.0
    }
}
