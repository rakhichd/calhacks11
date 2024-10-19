//
//  ContentView.swift
//  Spot the Op
//
//  Created by rakhi c on 10/18/24.
//

import SwiftUI

//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}

struct ContentView: View {
  var body: some View {
    TabView {
      // Home Screen with list of games
      HomeView()
        .tabItem {
          Label("Home", systemImage: "house")
        }

      // Second screen (e.g., Profile)
      ProfileView()
        .tabItem {
          Label("Profile", systemImage: "person.circle")
        }

      // Third screen (e.g., Settings)
      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
    }
  }
}

#Preview {
    ContentView()
}
