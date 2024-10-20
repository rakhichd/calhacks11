import SwiftUI
import GoogleMaps
import GoogleMapsUtils // Import GoogleMapsUtils for heatmap functionality
import CoreLocation
import UIKit


// MARK: - Models and Enums

// Updated Game model with spottedHistory
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
    @State private var newDescription = ""
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
                
                Section(header: Text("Generate Image From Description")) {
                    VStack {
                        HStack {
                            TextField("Enter Funny Description", text: $newDescription)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                generateImageFromDescription(prompt: newDescription) { imageData in
                                    if let imageData = imageData, let image = UIImage(data: imageData) {
                                        // Successfully got image data, update the UI
                                        DispatchQueue.main.async {
                                            self.selectedImage = image
                                        }
                                    } else {
                                        // Handle invalid image data case
                                        print("Invalid image data received")
                                    }
                                }
                            }) {
                                Text("Generate Image")
                                    .padding(8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }

                            
                        }

                        // Conditionally show the generated image if available
                        if let generatedImage = selectedImage {
                            Image(uiImage: generatedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .padding(.top) // Add some padding between the button and image
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

        // Create a new SpottedLocation object with the provided latitude, longitude, and image
        let spottedLocation = SpottedLocation(latitude: latitude, longitude: longitude, timestamp: Date(), personSpotted: personSpotted, imageData: imageData)

        // Update the game's spotted history
        game.spottedHistory.append(spottedLocation)

        // Clear the input field and selection
        newPersonName = ""
        selectedPerson = ""
        newDescription = ""

        // Close the modal
        showSpotModal = false
    }
    
   
    func generateImageFromDescription(prompt: String, completion: @escaping (Data?) -> Void) {
        // Construct the URL (no query parameters for POST)
        let urlString = "https://api.hyperbolic.xyz/v1/image/generation"
        
        // Check if the URL is valid
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: 60.0)
        request.httpMethod = "POST" // Use POST method
        
        // Set the request headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtb2hhbnh1QGJlcmtlbGV5LmVkdSIsImlhdCI6MTcyOTM5MzIyOX0.vXFeqFzFn-dQmaT24KPcfcp9ThHMMHzIUZ_z1teg_4E", forHTTPHeaderField: "Authorization")

        // Create the body with the prompt as JSON
        let body: [String: Any] = [
            "model_name": "FLUX.1-dev",   // Example model name (use the correct one)
            "prompt": prompt,             // The prompt provided by the user
            "steps": 30,                  // Example parameters (adjust if necessary)
            "cfg_scale": 5,
            "enable_refiner": false,
            "height": 1024,
            "width": 1024,
            "backend": "auto"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error creating JSON body: \(error)")
            completion(nil)
            return
        }

        // Create the data task for the URLSession
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle networking errors
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // Ensure data is not nil
            guard let data = data else {
                print("Error: No data received")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // Log the raw response data for debugging
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Response Data: \(rawResponse)")
            }

            do {
                // Parse the JSON response
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let images = json["images"] as? [[String: Any]],
                   let base64ImageString = images.first?["image"] as? String {
                    
                    // Decode the base64 string to Data
                    print("Base64 Image String: \(base64ImageString)")
                    if let imageData = Data(base64Encoded: base64ImageString, options: .ignoreUnknownCharacters) {
                        // Return the raw Data (binary image data)
                        
                        DispatchQueue.main.async {
                            completion(imageData)
                        }
                    } else {
                        print("Error: Failed to decode base64 image data")
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } else {
                    print("Error: Invalid JSON format or missing 'image' key")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                // Handle any JSON parsing errors
                print("Error parsing JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }

        // Start the network request
        task.resume()
    
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
        GameDetailView(game: Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585))
    }
}
