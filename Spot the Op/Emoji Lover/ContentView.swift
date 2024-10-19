import SwiftUI

// ContentView with TabView structure
struct ContentView: View {
    
    @EnvironmentObject var appController: AppController
    var body: some View {
        Group {
                    switch appController.authState {
                    case .undefined:
                        ProgressView() // Show a loading indicator while checking auth state
                    case .authenticated:
                        ProfileView() // Show profile view if authenticated
                    case .notAuthenticated:
                        AuthView() // Show login/signup view if not authenticated
                    }
        }
//        TabView {
//            // Home Screen with Google Maps
//            HomeView() // This is from HomeView.swift
//                .tabItem {
//                    Label("Home", systemImage: "house")
//                }
//
//            // Second screen (Profile)
//            ProfileView()
//                .tabItem {
//                    Label("Profile", systemImage: "person.circle")
//                }
//
//            // Third screen (Settings)
//            SettingsView()
//                .tabItem {
//                    Label("Settings", systemImage: "gear")
//                }
//        }
    }
}

#Preview {
    ContentView()
}

// SwiftUI App structure
//@main
//struct YourApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView() // Main content view is loaded here
//        }
//    }
//}


