import SwiftUI
import GoogleMaps
import GoogleMapsUtils // Import GoogleMapsUtils for heatmap functionality
import CoreLocation
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

// MARK: - Models and Enums

// Updated Game model with spottedHistory
// Updated Game model with spottedHistory
struct Game: Identifiable {
//    let id = UUID()
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let mode: GameMode?
    let invitedFriends: [String]
    var spottedHistory: [SpottedLocation] // List of spotted locations

    init(id: String, name: String, latitude: Double, longitude: Double, mode: GameMode? = nil, invitedFriends: [String] = [], spottedHistory: [SpottedLocation] = []) {
        self.name = name
        self.id = id
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
    let personSpotted: String
    var imageData: Data? // Optional data to store the image
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
            var spotFrequency: [String: Int] = [:]
            
            // Group spots by their latitude and longitude (rounded for vicinity)
            for spot in spots {
                let lat = round(spot.latitude * 10000) / 10000 // Increased precision to 4 decimal places (~10 meters)
                let lng = round(spot.longitude * 10000) / 10000
                let key = "\(lat),\(lng)"
                
                // Increment the frequency for this location
                spotFrequency[key, default: 0] += 1
            }

            // Prepare heatmap data with adjusted intensity based on frequency
            for (key, count) in spotFrequency {
                let coordinates = key.split(separator: ",")
                if let lat = Double(coordinates[0]), let lng = Double(coordinates[1]) {
                    let coords = GMUWeightedLatLng(
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                        intensity: Float(count) // The more frequent, the higher the intensity
                    )
                    list.append(coords)
                }
            }

            // Create the heatmap layer and add the data
            let heatmapLayer = GMUHeatmapTileLayer()
            heatmapLayer.weightedData = list
            heatmapLayer.radius = 80 // Increased the radius for a more spread-out heat effect
            heatmapLayer.map = mapView
            self.heatmapLayer = heatmapLayer
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey("AIzaSyAYOhICkLqvWUF1FQeR9AJRmYSlPTg765s") // Replace with your Google Maps API Key
        
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

//                    Text("Latitude: \(game.latitude)")
//                    Text("Longitude: \(game.longitude)")

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

                    // Display spotted history with image preview (if available)
                    if !game.spottedHistory.isEmpty {
                        Text("Spotted History:")
                            .font(.headline)
                        ForEach(game.spottedHistory) { spot in
                            VStack(alignment: .leading) {
                                Text("Person: \(spot.personSpotted)")
                                Text("Latitude: \(spot.latitude), Longitude: \(spot.longitude)")
                                Text("Timestamp: \(spot.timestamp, formatter: DateFormatter.spotFormatter)")
                                
                                // Show image if available
                                if let imageData = spot.imageData, let image = UIImage(data: imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(10)
                                }
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
            SpotModalView(game: $game, showSpotModal: $showSpotModal, locationManager: locationManager)
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
    @ObservedObject var locationManager: LocationManager
    @State private var selectedImage: UIImage? = nil // Store the selected image
    @State private var showImagePicker = false // Control for showing the image picker

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

                Section(header: Text("Upload an image")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    } else {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Text("Choose Image")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                

                Button(action: {
                    if let currentLocation = locationManager.location {
                        let latitude = currentLocation.coordinate.latitude
                        let longitude = currentLocation.coordinate.longitude
                        spotSomeone(latitude: latitude, longitude: longitude)
                    } else {
                        let latitude = 37.874942
                        let longitude = -122.2703
                        spotSomeone(latitude: latitude, longitude: longitude)
                    }
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }

    // Function to add a new spotted location using preset coordinates and image
    func spotSomeone(latitude: Double, longitude: Double) {
        let personSpotted = newPersonName.isEmpty ? selectedPerson : newPersonName

        // Convert selected image to Data for storage
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        
        let currTime = Date()

        if let imageDataR = selectedImage?.jpegData(compressionQuality: 0.8) {
            // Upload image if selected
            uploadImageToFirebase(imageData: imageDataR) { downloadURL, error in
                if let error = error {
                    print("Failed to upload image: \(error.localizedDescription)")
                    
                    // Call gameDbUpdate with nil if upload fails
                    gameDbUpdate(gameId: game.id, latitude: latitude, longitude: longitude, personName: personSpotted, timestamp: currTime, imgData: nil)
                } else if let downloadURL = downloadURL {
                    print("Image URL: \(downloadURL)")
                    
                    // Call gameDbUpdate with the download URL as an optional String
                    gameDbUpdate(gameId: game.id,latitude: latitude, longitude: longitude, personName: personSpotted, timestamp: currTime, imgData: downloadURL)
                    
                    // Update game spotted history with image URL
                    let spottedLocation = SpottedLocation(latitude: latitude, longitude: longitude, timestamp: currTime, personSpotted: personSpotted)
                    game.spottedHistory.append(spottedLocation)
                }
            }
        } else {
            // No image selected, proceed without uploading an image
            print("No image selected.")
            
            // Call gameDbUpdate with nil for imgData
            gameDbUpdate(gameId: game.id, latitude: latitude, longitude: longitude, personName: personSpotted, timestamp: currTime, imgData: nil)
            
            // Optionally update game spotted history without image
            let spottedLocation = SpottedLocation(latitude: latitude, longitude: longitude, timestamp: currTime, personSpotted: personSpotted)
            game.spottedHistory.append(spottedLocation)
        }


        // Clear the input field and selection
        newPersonName = ""
        selectedPerson = ""

        // Close the modal
        showSpotModal = false
    }
    
    func uploadImageToFirebase(imageData: Data, completion: @escaping (String?, Error?) -> Void) {
        // Create a unique identifier for the image
        let imageUUID = UUID().uuidString
        print(imageUUID)
        // Reference to Firebase Storage
        let storageRef = Storage.storage().reference().child("images/\(imageUUID).jpg")
        
        // Upload image data
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            // Fetch the download URL
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error fetching download URL: \(error.localizedDescription)")
                    completion(nil, error)
                } else if let downloadURL = url?.absoluteString {
                    print("Image successfully uploaded. Download URL: \(downloadURL)")
                    completion(downloadURL, nil)
                }
            }
        }
    }
    
    func gameDbUpdate(gameId: String, latitude: Double, longitude: Double, personName: String, timestamp: Date, imgData: String?) {
        let db = Firestore.firestore()
        
        // Reference to the specific game document by ID
        let gameRef = db.collection("games").document(gameId)

        // Prepare the spotted location to be added
        let spottedLocation: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "personSpotted": personName,
            "timestamp": timestamp,
            "imageData": imgData ?? ""
        ]

        // Update the game's spotted history by appending the new spotted location
        gameRef.updateData([
            "spottedHistory": FieldValue.arrayUnion([spottedLocation])
        ]) { error in
            if let error = error {
                print("Error updating game spotted history: \(error.localizedDescription)")
            } else {
                print("Game spotted history updated successfully!")
            }
        }
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

// MARK: - Image Picker for Image Selection
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Preview

// Optional preview provider for SwiftUI previews
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameDetailView(game: Game(id: "50BCBFB2-D9BD-4888-A56B-BC2A3F7F75E1", name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585))
    }
}
