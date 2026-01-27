//
//  FirebaseUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/26/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import FirebaseAuth

struct FirebaseUtils {

    static func checkFirebaseUser(userSettings: UserSettings) {
        if (Auth.auth().currentUser == nil) {
            Auth.auth().signInAnonymously {(authResult, error) in
                if (error == nil) {
                    userSettings.user = authResult?.user
                }
            }
        }
    }
}
