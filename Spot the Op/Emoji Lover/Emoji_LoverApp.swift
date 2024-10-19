//
//  Emoji_LoverApp.swift
//  Emoji Lover
//
//  Created by Mahit Namburu on 7/29/23.
//

//import SwiftUI
//import Firebase
//
////@main
//struct Emoji_LoverApp: App {
//    init() {
//            FirebaseApp.configure() // Initialize Firebase
//        }
//    
//    var body: some Scene {
//        WindowGroup {
//            
//            ContentView()
//        }
//    }
//}

import SwiftUI
import FirebaseCore

@main
struct YourApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var appController = AppController()
  var body: some Scene {
    WindowGroup {
//      NavigationView {
        ContentView()
              .environmentObject(appController)
              .onAppear {
                  appController.listenToAuthChanges()
              }
//      }
    }
  }
}
