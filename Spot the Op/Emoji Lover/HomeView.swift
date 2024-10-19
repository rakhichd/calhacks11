import SwiftUI

// A simple model to represent a game with a name and location (latitude and longitude)
struct Game: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

// HomeView with Google Maps for each game and a Create Games button
struct HomeView: View {
    // Array of games with their respective locations
    @State private var games = [
        Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585), // UC Berkeley
        Game(name: "UCLA", latitude: 34.0689, longitude: -118.4452),        // UCLA
        Game(name: "UC San Diego", latitude: 32.8801, longitude: -117.2340) // UC San Diego
    ]

    @State private var showingCreateGameSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(games) { game in
                        // Wrap each game in a NavigationLink
                        NavigationLink(destination: GameDetailView(game: game)) {
                            VStack(alignment: .leading) {
                                Text(game.name)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                GoogleMapView(game: game)
                                    .frame(height: 200)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.bottom, 200)
            }
            .navigationTitle("Your Games")
            .navigationBarItems(trailing:
                Button(action: {
                    showingCreateGameSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                }
            )
            .sheet(isPresented: $showingCreateGameSheet) {
                CreateGameView { newGame in
                    games.append(newGame)
                }
            }
        }
    }
}

// Optional preview provider for SwiftUI previews
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

