//
//  AppController.swift
//  Emoji Lover
//
//  Created by rakhi c on 10/19/24.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

enum AuthState {
    case undefined
    case authenticated
    case notAuthenticated
}

class AppController: ObservableObject {
    // Define any published properties here
//    @Published var someState: String = "Initial State"
    
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var authState: AuthState = .undefined
    
    private var db = Firestore.firestore()
    
    
    func listenToAuthChanges() {
                Auth.auth().addStateDidChangeListener { auth, user in
                    // Update authState based on the presence of the user
                    self.authState = user != nil ? .authenticated : .notAuthenticated
                }
            }
    
    func signUp() async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        let userData: [String: Any] = [
                "email": email,
                "games": [] // Initialize with an empty array of games
            ]
        
        try await db.collection("users").document(userId).setData(userData, merge: true)
            print("User created and added to Firestore: \(userId)")
        
    }
    
    func signIn() async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
        
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    

}

