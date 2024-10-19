import SwiftUI
import GoogleMaps

// A simple model to represent a game with a name and location (latitude and longitude)
struct Game {
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

// HomeView with Google Maps for each game
struct HomeView: View {
    // Array of 3 games with their respective locations
    let games = [
        Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585), // UC Berkeley
        Game(name: "UCLA", latitude: 34.0689, longitude: -118.4452),        // UCLA
        Game(name: "UC San Diego", latitude: 32.8801, longitude: -117.2340) // UC San Diego
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(games, id: \.name) { game in
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
    }
}

// Optional preview provider for SwiftUI previews
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
