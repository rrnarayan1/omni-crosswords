//
//  FirebaseUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/26/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore

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

    static func getNewCrosswords<T>(lastDate: Date, subscriptions: Array<String>,
                                    handler: FirebaseHandler<T>) {
        let db = Firestore.firestore()
        let docRef: Query = db.collection("crosswords")
            .whereField("date", isGreaterThanOrEqualTo: lastDate)
            .whereField("crossword_outlet_name", in: subscriptions)
            .limit(to: 100)

        docRef.getDocuments {(querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    handler.documentHandler(document, handler.data)
                }
            }
            if (handler.completionHandler != nil) {
                handler.completionHandler!(handler.data)
            }
        }
    }

    static func getNewAlerts<T>(lastAlertId: Int, handler: FirebaseHandler<T>){
        let db = Firestore.firestore()
        let alertDocRef: Query = db.collection("alerts")
            .whereField("id", isGreaterThan: lastAlertId)
            .order(by: "id", descending: true)
        alertDocRef.getDocuments {(querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                if (querySnapshot!.documents.count > 0) {
                    let document = querySnapshot!.documents[0]
                    handler.documentHandler(document, handler.data)
                }
            }
        }
        if (handler.completionHandler != nil) {
            handler.completionHandler!(handler.data)
        }
    }

    static func getNewOverwrites<T>(handler: FirebaseHandler<T>){
        let db = Firestore.firestore()
        let overwrittenCrosswords: Query = db.collection("crosswords")
            .whereField("version", isGreaterThan: 0)
            .limit(to: 100)
        overwrittenCrosswords.getDocuments {(querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    handler.documentHandler(document, handler.data)
                }
            }
        }
        if (handler.completionHandler != nil) {
            handler.completionHandler!(handler.data)
        }
    }
}

struct FirebaseHandler<T> {
    let data: T
    let documentHandler: (QueryDocumentSnapshot, T) -> Void
    let completionHandler: ((T) -> Void)?
}
