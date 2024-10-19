import SwiftUI
import GoogleMaps

// A simple model to represent a game with a name and location (latitude and longitude)
struct Game: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

// Create a UIViewRepresentable to wrap the GMSMapView
struct GoogleMapView: UIViewRepresentable {
    var game: Game

    // Coordinator to handle gesture recognizers
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        // Allow simultaneous gesture recognition
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }

    func makeUIView(context: Context) -> GMSMapView {
        // Provide the API Key for Google Maps services
        GMSServices.provideAPIKey("AIzaSyAYOhICkLqvWUF1FQeR9AJRmYSlPTg765s") // Replace with your actual API key

        // Set up the Google Map camera with the game's specific latitude, longitude, and zoom level
        let camera = GMSCameraPosition.camera(withLatitude: game.latitude, longitude: game.longitude, zoom: 10.0)

        // Initialize the GMSMapView using init()
        let mapView = GMSMapView()
        mapView.camera = camera
        mapView.settings.zoomGestures = true // Enable pinch-to-zoom functionality

        // Set the gesture recognizer delegates to the coordinator
        if let gestureRecognizers = mapView.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                gestureRecognizer.delegate = context.coordinator
            }
        }

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // You can update the map view here if needed
    }
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
                        VStack(alignment: .leading) {
                            Text(game.name) // Display the game name
                                .font(.headline)
                                .padding(.horizontal)

                            // Display the Google Map for each game
                            GoogleMapView(game: game)
                                .frame(height: 200) // Reduced frame height for a smaller map
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.bottom, 200) // Add extra padding to avoid content being cut off
            }
            .navigationTitle("Your Games")
            .navigationBarItems(trailing:
                Button(action: {
                    // Show the create game sheet
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

// CreateGameView allows the user to input new game details
struct CreateGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var latitudeText = ""
    @State private var longitudeText = ""

    var onCreate: (Game) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Details")) {
                    TextField("Name", text: $name)
                    TextField("Latitude", text: $latitudeText)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitudeText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Create Game")
            .navigationBarItems(leading:
                Button("Cancel") {
                    // Dismiss the sheet without saving
                    presentationMode.wrappedValue.dismiss()
                },
                trailing:
                Button("Save") {
                    // Validate inputs and create a new game
                    if let latitude = Double(latitudeText),
                       let longitude = Double(longitudeText),
                       !name.isEmpty {
                        let newGame = Game(name: name, latitude: latitude, longitude: longitude)
                        onCreate(newGame)
                        // Dismiss the sheet after saving
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(name.isEmpty || Double(latitudeText) == nil || Double(longitudeText) == nil)
            )
        }
    }
}

// Optional preview provider for SwiftUI previews
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
