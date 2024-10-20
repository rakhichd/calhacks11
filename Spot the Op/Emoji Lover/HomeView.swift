import SwiftUI
import GoogleMaps
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Firebase


// MARK: - Home View
enum InviteOption: String, CaseIterable, Identifiable {
    case viaLink = "Via Link"
    case viaUsername = "Via Username"
    case none = "None"

    var id: String { self.rawValue }
}

struct HomeView: View {
    // Observed object for location
    @ObservedObject var locationManager: LocationManager
    @State private var games: [Game] = []

    // State variable to control the presentation of the create game sheet
    @State private var showingCreateGame = false

    // State variable for location authorization
    @State private var isAuthorized: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(games) { game in
                        // Wrap each game in a NavigationLink to GameDetailView
                        NavigationLink(destination: GameDetailView(gameId: game.id)) {
                            VStack(alignment: .leading) {
                                Text(game.name)
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .bold()
                                    .foregroundColor(Color(red: 0.75, green: 0.87, blue: 0.97)) // Light pastel blue
                                    .padding(.horizontal)

                                // Display the game mode if needed
                                if let mode = game.mode {
                                    Text("Mode: \(mode.rawValue)")
                                        .font(.custom("PressStart2P-Regular", size: 12))
                                        .foregroundColor(Color(red: 0.95, green: 0.76, blue: 0.98)) // Light pastel pink
                                        .padding(.horizontal)
                                }

                                // Display invited friends if any
                                if !game.invitedFriends.isEmpty {
                                    Text("Invited Friends: \(game.invitedFriends.joined(separator: ", "))")
                                        .font(.custom("PressStart2P-Regular", size: 12))
                                        .foregroundColor(Color(red: 0.8, green: 0.95, blue: 0.8)) // Light pastel green
                                        .padding(.horizontal)
                                }

                                // Display the Google Map for each game
                                GoogleMapView(game: game)
                                    .frame(height: 200) // Reduced frame height for a smaller map
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .background(Color.black.opacity(0.8)) // Dark background for game card
                            .cornerRadius(15)
                            .shadow(color: .black, radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.bottom, 20) // Add extra padding to avoid content being cut off
                }
            }
            .background(Color.black) // Dark background for the entire view
            .navigationTitle("Your Games")
            .foregroundColor(.white) // Set the text color to white
            // Add the Create Game button in the navigation bar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateGame = true
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title)
                            .foregroundColor(Color(red: 0.75, green: 0.87, blue: 0.97)) // Light pastel blue
                    }
                }
            }
            // Present the create game sheet when the button is tapped
            .sheet(isPresented: $showingCreateGame) {
                CreateGameView { newGame in
                    games.append(newGame)
                }
                .preferredColorScheme(.dark) // Force the sheet to use dark mode
            }
        }
        .preferredColorScheme(.dark) // Force dark mode throughout the app
      .onAppear {
                        fetchUserGames()
                    }
    }
    }
}
    
    private func fetchUserGames() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }

        // Clear the games array before fetching the new games to prevent duplicates
        games.removeAll()

        // Reference to the user's document
        let userRef = Firestore.firestore().collection("users").document(currentUser.uid)

        // Fetch the user's game IDs from the user's document
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user games: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists,
                  let data = document.data(),
                  let gameIDs = data["games"] as? [String] else {
                print("No games found for the user.")
                return
            }

            // Fetch the actual games using the game IDs
            self.fetchGames(gameIDs: gameIDs)
        }
    }
    
    private func fetchGames(gameIDs: [String]) {
        let gamesCollection = Firestore.firestore().collection("games")

        // Create a DispatchGroup to handle multiple async calls
        let group = DispatchGroup()

        for gameID in gameIDs {
            group.enter() // Enter the group before starting each fetch
            
            // Log the gameID being fetched
            print("Fetching game with ID: \(gameID)")
            
            gamesCollection.document(gameID).getDocument { (document, error) in
                defer {
                    group.leave() // Ensure the group leave is called
                }

                if let error = error {
                    print("Error fetching game \(gameID): \(error.localizedDescription)")
                    return
                }

                guard let document = document, document.exists, let data = document.data() else {
                    print("Game \(gameID) not found or document does not exist")
                    return
                }
                

                // Log the document data
                print("Document data for \(gameID): \(data)")

                // Check individual fields
                let gameName = data["gameName"] as? String ?? "Unknown Game"
                let latitude = data["latitude"] as? Double ?? 0.0
                let longitude = data["longitude"] as? Double ?? 0.0
                let gameMode = GameMode(rawValue: data["gameMode"] as? String ?? "")

                print("Parsed Game - Name: \(gameName), Latitude: \(latitude), Longitude: \(longitude), Mode: \(gameMode?.rawValue ?? "Unknown")")

                print("Fetched game data for ID \(gameID): \(data)") // Log the document data
                
                // Convert Firestore document data into Game model
                let game = Game(
                    id: gameID,  // gameID is already a String
                    name: data["gameName"] as? String ?? "Unknown Game",  // Default to "Unknown Game" if no name found
                    latitude: data["latitude"] as? Double ?? 0.0,
                    longitude: data["longitude"] as? Double ?? 0.0,
                    mode: GameMode(rawValue: data["gameMode"] as? String ?? ""),
                    invitedFriends: data["invitedFriends"] as? [String] ?? [],
                    spottedHistory: self.parseSpottedHistory(data: data["spottedHistory"] as? [[String: Any]] ?? [])
                )

                // Only append the game if it doesn't already exist in the games array
                if !self.games.contains(where: { $0.id == game.id }) {
                    self.games.append(game) // Append the fetched game to the games array
                    print("Game with ID \(gameID) added to the games array.")
                } else {
                    print("Game with ID \(gameID) already exists in the games array.")
                }
            }
        }

        group.notify(queue: .main) {
            print("Finished fetching games. Total games: \(self.games.count)")
            print("Games Included. Total games: \(self.games)")
        }
    }


    private func parseSpottedHistory(data: [[String: Any]]) -> [SpottedLocation] {
        return data.compactMap { dict in
            guard let latitude = dict["latitude"] as? Double,
                  let longitude = dict["longitude"] as? Double,
                  let personSpotted = dict["personSpotted"] as? String,
                  let timestamp = dict["timestamp"] as? Timestamp else {
                return nil
            }

            return SpottedLocation(
                latitude: latitude,
                longitude: longitude,
                timestamp: timestamp.dateValue(),
                personSpotted: personSpotted
            )
        }

// MARK: - Create Game View

// View for creating a new game with mode selection and inviting friends
struct CreateGameView: View {
    @Environment(\.presentationMode) var presentationMode
    var onAddGame: (Game) -> Void

    @State private var name = ""
    @State private var selectedMode: GameMode = .spotMyEx
    @StateObject private var locationManager = LocationManager()

    // Inviting friends
    @State private var inviteOption: InviteOption = .none
    @State private var shareLink: String = ""
    @State private var username: String = ""
    @State private var invitedUsernames: [String] = []
    
    private var db = Firestore.firestore()
    
    init(onAddGame: @escaping (Game) -> Void) {
            self.onAddGame = onAddGame
        }

    var body: some View {
        NavigationView {
            Form {
                // Section for inviting friends
                Section(header: Text("Invite Friends").foregroundColor(.white)) {
                    Picker("Invite Option", selection: $inviteOption) {
                        ForEach(InviteOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .foregroundColor(.white)

                    if inviteOption == .viaLink {
                        Button(action: {
                            generateShareLink()
                        }) {
                            Text("Generate Shareable Link")
                        }
                        if !shareLink.isEmpty {
                            Text("Share this link with your friends:")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text(shareLink)
                                .foregroundColor(.blue)
                                .textSelection(.enabled)
                        }
                    } else if inviteOption == .viaUsername {
                        TextField("Enter Friend's Username", text: $username)
                            .foregroundColor(.white)
                        Button(action: {
                            addUsername()
                        }) {
                            Text("Add Friend")
                        }
                        .disabled(username.isEmpty)
                        if !invitedUsernames.isEmpty {
                            Text("Invited Friends: \(invitedUsernames.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .listRowBackground(Color.black.opacity(0.7)) // Dark background for each section

                Section(header: Text("Game Mode").foregroundColor(.white)) {
                    Picker("Select Game Mode", selection: $selectedMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .foregroundColor(.white)
                }
                .listRowBackground(Color.black.opacity(0.7))

                Section(header: Text("Game Details").foregroundColor(.white)) {
                    TextField("Name", text: $name)
                        .foregroundColor(.white)

                    if selectedMode == .custom {
                        if let location = locationManager.location {
                            Text("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                                .foregroundColor(.white)
                        } else {
                            Text("No location data available. Enable location in settings.")
                                .foregroundColor(.red)
                        }

                    }
                }
                .listRowBackground(Color.black.opacity(0.7))
            }
            .background(Color.black) // Dark background for the form
            .onAppear {
                if selectedMode == .custom {
                    locationManager.requestLocation()
                }
            }
            .onChange(of: selectedMode) { _ in
                if selectedMode == .custom {
                    locationManager.requestLocation()
                }
            }
            .onChange(of: locationManager.authorizationStatus) { status in
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    locationManager.requestLocation()
                }
            }
            .navigationTitle("Create Game")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }.foregroundColor(.white), trailing: Button("Add") {
                addGame()
                presentationMode.wrappedValue.dismiss()
            }.disabled(!canAddGame)
            .foregroundColor(.white))
        }
        .preferredColorScheme(.dark) // Force dark mode for the sheet
    }

    var canAddGame: Bool {
        // Validate input
        if name.isEmpty { return false }

        if selectedMode == .custom {
            if locationManager.location == nil { return false }
        }
        return true
    }

    func addGame() {
        let lat: Double
        let lon: Double

        switch selectedMode {
        case .spotMyEx:
            if let userLocation = locationManager.location {
                lat = userLocation.coordinate.latitude
                lon = userLocation.coordinate.longitude
            } else {
                lat = 40.7128 // Example latitude (New York City)
                lon = -74.0060 // Example longitude
            }
        case .spotMyOp:
            if let userLocation = locationManager.location {
                lat = userLocation.coordinate.latitude
                lon = userLocation.coordinate.longitude
            } else {
                lat = 40.7128 // Example latitude (New York City)
                lon = -74.0060 // Example longitude
            }
        case .custom:
            if let userLocation = locationManager.location {
                lat = userLocation.coordinate.latitude
                lon = userLocation.coordinate.longitude
            } else {
                return // Location not available
            }
        }

        let newGame = Game(id: "", name: name, latitude: lat, longitude: lon, mode: selectedMode, invitedFriends: invitedUsernames)
        createGameForDb(name:name, lat:lat, lon:lon, mode:selectedMode, invitedUsernames:invitedUsernames)
        onAddGame(newGame)
    }

    func generateShareLink() {
        shareLink = "https://myapp.com/join?gameId=\(UUID().uuidString)"
    }

    func addUsername() {
        invitedUsernames.append(username)
        username = ""
    }
    
    func createGameForDb(name:String, lat:Double, lon:Double, mode:GameMode? = nil, invitedUsernames: [String] = []) {
  
        guard let currentUser = Auth.auth().currentUser else {
                print("No user is currently logged in.")
                return // Exit the function or handle the situation appropriately
            }
            let userId = currentUser.uid
        
        let gameID = UUID().uuidString
        
        let gameData: [String: Any] = [
                "gameMode": mode?.rawValue as Any, // Store the game mode as Any type
                "gameName": name as Any, // Game name as String
                "invitedFriends": invitedUsernames + [userId] as [String], // Combine arrays and ensure it's of String type
                "latitude": lat as Double, // Latitude as Double
                "longitude": lon as Double, // Longitude as Double
                "spottedHistory": [] as [[String: Any]] // Initialize spotted history as an empty array of dictionaries
            ]
        
        let gamesCollection = db.collection("games")
        
        gamesCollection.document(gameID).setData(gameData, merge: true)
        
        let userDocument = db.collection("users").document(userId)
        
        userDocument.updateData(["games": FieldValue.arrayUnion([gameID])]) { error in
                        if let error = error {
                            print("Error adding gameID to user's games array: \(error.localizedDescription)")
                        } else {
                            print("Game ID appended to user's games: \(gameID)")
                        }
                    }
    }
    
}
