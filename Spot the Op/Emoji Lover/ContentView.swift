import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        Group {
            switch appController.authState {
            case .undefined:
                ProgressView() // Show a loading indicator while checking auth state
                
            case .authenticated:
                TabView {
                    // Home Screen with Google Maps
                    HomeView() // This is from HomeView.swift
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    // Profile Screen
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }

                    // Settings Screen
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                
            case .notAuthenticated:
                AuthView() // Show login/signup view if not authenticated
            }
        }
    }
}


#Preview {
    ContentView()
}



