import SwiftUI

// ContentView with TabView structure
struct ContentView: View {
    var body: some View {
        TabView {
            // Home Screen with Google Maps
            HomeView() // This is from HomeView.swift
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            // Second screen (Profile)
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }

            // Third screen (Settings)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}


// SwiftUI App structure
@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView() // Main content view is loaded here
        }
    }
}
