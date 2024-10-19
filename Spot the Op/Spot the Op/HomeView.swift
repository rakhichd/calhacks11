//
//  Home.swift
//  Spot the Op
//
//  Created by rakhi c on 10/19/24.
//

import SwiftUI

//struct HomeView: View {
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

struct HomeView: View {
  let games = ["Game 1", "Game 2", "Game 3", "Game 4"] // Placeholder for current games

  var body: some View {
    NavigationView {
      List(games, id: \.self) { game in
        Text(game) // Display game name
      }
      .navigationTitle("Your Games")
    }
  }
}

#Preview {
    HomeView()
}
