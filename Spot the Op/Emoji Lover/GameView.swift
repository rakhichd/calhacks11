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
    @StateObject private var viewModel = GameViewModel() // ViewModel to fetch game data
    @State private var showSpotModal = false // Controls the display of the sheet
    @State private var selectedTab = 0 // Control for the tab view
    @State private var selectedGame: Game? // Store the selected game as @State
    var gameId: String // Pass the game ID to fetch the specific game
    
    var body: some View {
        VStack {
            if let game = selectedGame {
                tabView
            } else {
                loadingView
            }
        }
        .onAppear {
            // Fetch games when the view appears
            viewModel.fetchGames { games in
                selectedGame = games.first(where: { $0.id == gameId })
            }
        }
        .navigationTitle(selectedGame?.name ?? "Game Details") // Set navigation title
        .sheet(isPresented: $showSpotModal) {
            if let game = selectedGame {
                SpotModalView(game: game, showSpotModal: $showSpotModal, locationManager: locationManager)
            }
        }
    }
    
    private var loadingView: some View {
        Text("Loading games...") // Show loading text while fetching
    }
    
    private var tabView: some View {
        TabView(selection: $selectedTab) {
            gameDetailsTab
                .tabItem {
                    Label("Game", systemImage: "gamecontroller")
                }
                .tag(0)
            
            leaderboardTab
                .tabItem {
                    Label("Leaderboard", systemImage: "list.number")
                }
                .tag(1)
        }
    }
    
    private var gameDetailsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let game = selectedGame {
                    GoogleMapView(game: game)
                        .frame(height: 300)
                        .cornerRadius(10)
                        .padding()
                    
                    spotSomeoneButton
                    
                    if !game.spottedHistory.isEmpty {
                        spottedHistoryView(game: game)
                    }
                } else {
                    Text("Game not found") // In case the game is not found
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
//    private var leaderboardTab: some View {
//        Text("Leaderboard") // Placeholder for leaderboard view
//    }
    
    @State var results: [(String, Int)] = []
    
    private var leaderboardTab: some View {
        VStack(alignment: .leading) {
            Text("Leaderboard")
                .font(.headline)
                .padding()

            // Compute the top spotted people
            
            
            if results.isEmpty {
                Text("No one has been spotted yet.")
                    .padding()
            } else {
                // Display the top 5 people
                ForEach(results, id: \.0) { name, count in
                    HStack {
                        Text("\(name)") // Rank and person's name
                        Spacer()
                        Text("\(count) times") // Number of times they've been spotted
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .onAppear {
            getTopSpotted()
        }
    }
    func getTopSpotted() {
        // Create a dictionary to count occurrences of each person
        // get the storage, find the appropriate game with gameid, then iterate through spottedhistory
        
        let gamesCollection = Firestore.firestore().collection("games")
        var personCountArray:[(person: String, count: Int)] = []

        // Create a DispatchGroup to handle multiple async calls
        
        
        // Log the gameID being fetched
        print("Fetching game with ID: \(gameId)")
        
        gamesCollection.document(gameId).getDocument { (document, error) in
            if let error = error {
                print("Error fetching game \(gameId): \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("Game \(gameId) not found or document does not exist")
                return
            }
            var scores = [String: Int]()
            if let spottedHistoryArray = data["spottedHistory"] as? [[String: Any]] {
                    // Iterate over each dictionary in the array
                    for spot in spottedHistoryArray {
                        if let personSpotted = spot["personSpotted"] as? String {
                            print("Person spotted: \(personSpotted)")
                            scores[personSpotted, default:0] += 1
                        } else {
                            print("Person spotted data is missing or not a String")
                        }
                    }
                } else {
                    print("No valid spotted history data found")
            }
            print(scores)
            for (key, value) in scores {
                personCountArray.append((key, value)) // Append each tuple manually
            }
            print("right after assignment")
            print(personCountArray)
            let sortedArray = personCountArray.sorted { $0.1 > $1.1 }
            
            results = sortedArray
        }
    }
    
    
    
    private var spotSomeoneButton: some View {
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
    }
    
    private func spottedHistoryView(game: Game) -> some View {
        VStack(alignment: .leading) {
            Text("Spotted History:")
                .font(.headline)
            ForEach(game.spottedHistory) { spot in
                VStack(alignment: .leading) {
                    Text("Person: \(spot.personSpotted)")
                    Text("Latitude: \(spot.latitude), Longitude: \(spot.longitude)")
                    Text("Timestamp: \(spot.timestamp, formatter: DateFormatter.spotFormatter)")
                    // Handle image rendering if needed
                }
                .padding(.bottom, 5)
            }
        }
    }
}


// MARK: - Leaderboard View
struct LeaderboardView: View {
    let game: Game
    
    // Compute the top spotted people
    var topSpotted: [(person: String, count: Int)] {
        // Create a dictionary to count occurrences
        let spottedCount = Dictionary(grouping: game.spottedHistory.map { $0.personSpotted }, by: { $0 })
            .mapValues { $0.count }
        
        // Convert dictionary to an array and sort by count (descending)
        let sortedSpotted = spottedCount.sorted { $0.value > $1.value }
        
        // Take the top 5 people
        return Array(sortedSpotted.prefix(5)).map { (person: $0.key, count: $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if topSpotted.isEmpty {
                Text("No one has been spotted yet.")
                    .padding()
            } else {
                // Display the top 5 people
                ForEach(0..<topSpotted.count, id: \.self) { index in
                    let person = topSpotted[index]
                    HStack {
                        Text("\(index + 1). \(person.person)") // Rank and person's name
                        Spacer()
                        Text("\(person.count) times") // Number of times they've been spotted
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                }
            }
        }
        .padding()
    }
}

//struct LeaderboardView: View {
//    var game: Game // Pass the game as a parameter
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text("Leaderboard")
//                .font(.largeTitle)
//                .padding()
//
//            // Fetch the top 5 people
//            let topSpotted = game.topSpottedPeople()
//            
//            
//            ForEach(game.spottedHistory) { spot in
//                    Text("Person spotted: \(spot.personSpotted)")
//                }
//            
//
//            if topSpotted.isEmpty {
//                Text("No one has been spotted yet.")
//                    .padding()
//            } else {
//                // Display the top 5 people
//                ForEach(0..<topSpotted.count, id: \.self) { index in
//                    let person = topSpotted[index]
//                    HStack {
//                        Text("\(index + 1). \(person.person)")
//                        Spacer()
//                        Text("\(person.count) times")
//                    }
//                    .padding(.vertical, 5)
//                    .padding(.horizontal)
//                }
//            }
//
//            Spacer()
//        }
//        .padding()
//    }
//}

// MARK: - Spot Modal View

struct SpotModalView: View {
    @State var game: Game
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
        let currTime = Date()

        // Convert selected image to Data for storage
        if let imageData = selectedImage?.jpegData(compressionQuality: 0.5) {
            // Upload image if selected
            
            let imageName = UUID().uuidString
            
            uploadImageToFirebase(imageName:imageName, gameId: game.id, imageData: imageData) { downloadURL, error in
                if let error = error {
                    print("Failed to upload image: \(error.localizedDescription)")
                    
                    // Call gameDbUpdate with nil if upload fails
                    gameDbUpdate(gameId: game.id, latitude: latitude, longitude: longitude, personName: personSpotted, timestamp: currTime, imgData: nil)
                } else if let downloadURL = downloadURL {
                    print("Image URL: \(downloadURL)")
                    
                    // Call gameDbUpdate with the download URL as an optional String
                    gameDbUpdate(gameId: game.id, latitude: latitude, longitude: longitude, personName: personSpotted, timestamp: currTime, imgData: imageName)
                    
                    // Update game spotted history with image URL
                    let spottedLocation = SpottedLocation(latitude: latitude, longitude: longitude, timestamp: currTime, personSpotted: personSpotted, imageData: imageData)
                    game.spottedHistory.append(spottedLocation)
                }
            }
        } else {
            // No image selected, proceed without uploading an image
            print("No image selected.")
            gameDbUpdate(gameId: game.id, latitude: latitude, longitude: longitude, personName: personSpotted, timestamp: currTime, imgData: nil)
            
            let spottedLocation = SpottedLocation(latitude: latitude, longitude: longitude, timestamp: currTime, personSpotted: personSpotted)
            game.spottedHistory.append(spottedLocation)
        }

        // Reset input fields
        newPersonName = ""
        selectedPerson = ""
        showSpotModal = false
    }
    
    func uploadImageToFirebase(imageName: String, gameId: String, imageData: Data, completion: @escaping (String?, Error?) -> Void) {
        // Create a unique name for the image based on timestamp or UUID
        let storageRef = Storage.storage().reference().child("images/\(imageName).jpg")
        
        // Upload the image data to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error during image upload: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            // Once the upload is complete, fetch the download URL
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Failed to fetch download URL: \(error.localizedDescription)")
                    completion(nil, error)
                } else if let downloadURL = url?.absoluteString {
                    print("Successfully uploaded image. Download URL: \(downloadURL)")
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

//// Optional preview provider for SwiftUI previews
//struct GameView_Previews: PreviewProvider {
//    static var previews: some View {
//        GameDetailView(game: Game(id: "50BCBFB2-D9BD-4888-A56B-BC2A3F7F75E1", name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585))
//    }
//}
