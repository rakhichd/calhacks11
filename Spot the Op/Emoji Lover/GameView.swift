import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Models and Enums

// Updated Game model with spottedHistory
struct Game: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let mode: GameMode?
    let invitedFriends: [String]
    var spottedHistory: [SpottedLocation] // List of spotted locations

    init(name: String, latitude: Double, longitude: Double, mode: GameMode? = nil, invitedFriends: [String] = [], spottedHistory: [SpottedLocation] = []) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.mode = mode
        self.invitedFriends = invitedFriends
        self.spottedHistory = spottedHistory
    }
}

// Model to represent a spotted location
struct SpottedLocation: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let personSpotted: String // Add personSpotted to track who was spotted
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

// GameDetailView: Detailed view of a specific game with a tab bar for Game and Leaderboard
struct GameDetailView: View {
    @StateObject private var locationManager = LocationManager() // Use location manager to fetch current location
    @State private var game: Game // Keep game mutable
    @State private var isSpotting = false // Control the state for spotting
    @State private var showSpotModal = false // Controls the display of the sheet
    @State private var selectedTab = 0 // Control for the tab view

    init(game: Game) {
        _game = State(initialValue: game)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Game Details Tab
            ScrollView {
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

                    // Spot someone button with current location
                    Button(action: {
                        // Request location before showing modal
                        locationManager.requestLocation()
                        showSpotModal = true
                    }) {
                        Text("Spot Someone")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    // Display spotted history
                    if !game.spottedHistory.isEmpty {
                        Text("Spotted History:")
                            .font(.headline)
                        ForEach(game.spottedHistory) { spot in
                            VStack(alignment: .leading) {
                                Text("Person: \(spot.personSpotted)")
                                Text("Latitude: \(spot.latitude), Longitude: \(spot.longitude)")
                                Text("Timestamp: \(spot.timestamp, formatter: DateFormatter.spotFormatter)")
                            }
                            .padding(.bottom, 5)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .tabItem {
                Label("Game", systemImage: "gamecontroller")
            }
            .tag(0)

            // Leaderboard Tab
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "list.number")
                }
                .tag(1)
        }
        .navigationTitle(game.name)
        .sheet(isPresented: $showSpotModal) {
            SpotModalView(game: $game, showSpotModal: $showSpotModal, currentLocation: locationManager.location)
        }
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    var body: some View {
        VStack {
            Text("Leaderboard")
                .font(.largeTitle)
                .padding()
            Text("This is where the leaderboard will be displayed.")
                .padding()
            Spacer()
        }
    }
}

// MARK: - Spot Modal View

struct SpotModalView: View {
    @Binding var game: Game
    @Binding var showSpotModal: Bool
    @State private var newPersonName = "" // For new person
    @State private var selectedPerson = "" // For selecting an existing person
    var currentLocation: CLLocation? // Current location passed from LocationManager

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add a new person or select an existing one")) {
                    TextField("Enter new person's name", text: $newPersonName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if !game.spottedHistory.isEmpty {
                        Picker("Or choose from previously spotted", selection: $selectedPerson) {
                            ForEach(game.spottedHistory, id: \.personSpotted) { spot in
                                Text(spot.personSpotted).tag(spot.personSpotted)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Button(action: {
                    spotSomeone()
                }) {
                    Text("Add Spot")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newPersonName.isEmpty && selectedPerson.isEmpty)
            }
            .navigationBarTitle("Spot Someone", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showSpotModal = false
            })
        }
    }

    // Function to add a new spotted location
    func spotSomeone() {
        // Get the user's current location if available, otherwise fallback to preset coordinates
        let latitude = currentLocation?.coordinate.latitude ?? 40.730610 // New York City as default
        let longitude = currentLocation?.coordinate.longitude ?? -73.935242 // New York City as default

        // Determine the person spotted (either new or selected)
        let personSpotted = newPersonName.isEmpty ? selectedPerson : newPersonName

        let spottedLocation = SpottedLocation(latitude: latitude, longitude: longitude, timestamp: Date(), personSpotted: personSpotted)

        // Update the game's spotted history
        game.spottedHistory.append(spottedLocation)

        // Clear the input field and selection
        newPersonName = ""
        selectedPerson = ""

        // Close the modal
        showSpotModal = false
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

// DateFormatter for displaying timestamp in a user-friendly format
extension DateFormatter {
    static var spotFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Preview

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameDetailView(game: Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585))
    }
}
