//
//  FirebaseUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/26/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import FirebaseAuth

struct FirebaseUtils {

    static func getFirebaseUser() -> User? {
        return Auth.auth().currentUser
    }

    static func checkFirebaseUser(userSettings: UserSettings) {
        if (FirebaseUtils.getFirebaseUser() == nil) {
            Auth.auth().signInAnonymously {(authResult, error) in
                if (error == nil) {
                    userSettings.user = authResult?.user
                }
            }
        }
    }
}
