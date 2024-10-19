import SwiftUI
import GoogleMaps
import GoogleMapsUtils // Import GoogleMapsUtils for heatmap functionality
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

    // Method to get the top 5 most spotted people
    func topSpottedPeople(limit: Int = 5) -> [(person: String, count: Int)] {
        var spottedCount: [String: Int] = [:]
        for spot in spottedHistory {
            spottedCount[spot.personSpotted, default: 0] += 1
        }
        return spottedCount.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
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

// MARK: - Google Map View with Heatmap
struct GoogleMapView: UIViewRepresentable {
    var game: Game

    class Coordinator: NSObject, GMSMapViewDelegate {
        var heatmapLayer: GMUHeatmapTileLayer?

        // Function to add heatmap based on the spotted locations
        func addHeatMap(mapView: GMSMapView, spots: [SpottedLocation]) {
            var list = [GMUWeightedLatLng]()
            
            // Prepare heatmap data from the list of spotted locations
            for spot in spots {
                let coords = GMUWeightedLatLng(
                    coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
                    intensity: 1.0 // Each spot has equal intensity, you can customize it
                )
                list.append(coords)
            }

            // Create the heatmap layer and add the data
            let heatmapLayer = GMUHeatmapTileLayer()
            heatmapLayer.weightedData = list
            heatmapLayer.radius = 60 // You can adjust the radius for density effect
            heatmapLayer.map = mapView
            self.heatmapLayer = heatmapLayer
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey("YOUR_API_KEY") // Replace with your Google Maps API Key
        
        let camera = GMSCameraPosition.camera(withLatitude: game.latitude, longitude: game.longitude, zoom: 10.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        // Add the heatmap using the spotted history
        context.coordinator.addHeatMap(mapView: mapView, spots: game.spottedHistory)

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Remove the old heatmap layer if exists
        context.coordinator.heatmapLayer?.map = nil
        
        // Add a new heatmap layer when updating the view
        context.coordinator.addHeatMap(mapView: uiView, spots: game.spottedHistory)
    }
}

// MARK: - Game Detail View
struct GameDetailView: View {
    @StateObject private var locationManager = LocationManager() // Use location manager to fetch current location
    @State private var game: Game // Keep game mutable
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

                    // Spot someone button with current location
                    Button(action: {
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
            LeaderboardView(game: game)
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
    var game: Game // Pass the game as a parameter

    var body: some View {
        VStack(alignment: .leading) {
            Text("Leaderboard")
                .font(.largeTitle)
                .padding()

            // Fetch the top 5 people
            let topSpotted = game.topSpottedPeople()

            if topSpotted.isEmpty {
                Text("No one has been spotted yet.")
                    .padding()
            } else {
                // Display the top 5 people
                ForEach(0..<topSpotted.count, id: \.self) { index in
                    let person = topSpotted[index]
                    HStack {
                        Text("\(index + 1). \(person.person)")
                        Spacer()
                        Text("\(person.count) times")
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
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
        let latitude = currentLocation?.coordinate.latitude ?? 37.871900
        let longitude = currentLocation?.coordinate.longitude ?? -122.258500
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

// Optional preview provider for SwiftUI previews
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameDetailView(game: Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585))
    }
}
