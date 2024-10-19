// GameView.swift
import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Models and Enums

// Updated Game model with additional properties
struct Game: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let mode: GameMode?
    let invitedFriends: [String] // List of invited friends' usernames

    // Initialize with default values for mode and invitedFriends for compatibility
    init(name: String, latitude: Double, longitude: Double, mode: GameMode? = nil, invitedFriends: [String] = []) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.mode = mode
        self.invitedFriends = invitedFriends
    }
}

// Enum to represent game modes
enum GameMode: String, CaseIterable, Identifiable {
    case spotMyEx = "Spot my ex"
    case spotMyOp = "Spot my op"
    case custom = "Custom"

    var id: String { self.rawValue }
}

// MARK: - Google Map View

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
        GMSServices.provideAPIKey("YOUR_API_KEY") // Replace with your actual API key

        // Set up the Google Map camera with the game's specific latitude, longitude, and zoom level
        let camera = GMSCameraPosition.camera(withLatitude: game.latitude, longitude: game.longitude, zoom: 10.0)

        // Initialize the GMSMapView
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
        // Update the map view if needed
    }
}

// MARK: - Game Detail View

// GameDetailView: Detailed view of a specific game
struct GameDetailView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GoogleMapView(game: game)
                .frame(height: 300)
                .cornerRadius(10)
                .padding()

            Text("Latitude: \(game.latitude)")
            Text("Longitude: \(game.longitude)")

            // Display additional game details if available
            if let mode = game.mode {
                Text("Mode: \(mode.rawValue)")
            }
            if !game.invitedFriends.isEmpty {
                Text("Invited Friends: \(game.invitedFriends.joined(separator: ", "))")
            }

            Spacer()
        }
        .padding()
        .navigationTitle(game.name)
    }
}

// MARK: - Location Manager

// LocationManager to handle location updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            manager.requestLocation()
        }
    }

    // For iOS 14 and above
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        handleAuthorizationStatus()
    }

    // For iOS 13 and below
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        handleAuthorizationStatus()
    }

    private func handleAuthorizationStatus() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            manager.stopUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
        manager.stopUpdatingLocation() // Stop updates if you only need one location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with error: \(error.localizedDescription)")
    }
}
