// HomeView.swift
import SwiftUI
import GoogleMaps
import CoreLocation

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
    // Use @State to allow modification of the games array
    @State private var games = [
        Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585),
        Game(name: "UCLA", latitude: 34.0689, longitude: -118.4452),
        Game(name: "UC San Diego", latitude: 32.8801, longitude: -117.2340)
    ]

    // State variable to control the presentation of the create game sheet
    @State private var showingCreateGame = false
    
    //State Variable for location use auth
    @State private var isAuthorized: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(games) { game in
                        // Wrap each game in a NavigationLink to GameDetailView
                        NavigationLink(destination: GameDetailView(game: game)) {
                            VStack(alignment: .leading) {
                                Text(game.name)
                                    .font(.headline)
                                    .padding(.horizontal)

                                // Display the game mode if needed
                                if let mode = game.mode {
                                    Text("Mode: \(mode.rawValue)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                }

                                // Display invited friends if any
                                if !game.invitedFriends.isEmpty {
                                    Text("Invited Friends: \(game.invitedFriends.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal)
                                }

                                // Display the Google Map for each game
                                GoogleMapView(game: game)
                                    .frame(height: 200) // Reduced frame height for a smaller map
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 20) // Add extra padding to avoid content being cut off
                }
            }
            .navigationTitle("Your Games")
            // Add the Create Game button in the navigation bar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateGame = true
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title)
                    }
                }
            }
            // Present the create game sheet when the button is tapped
            .sheet(isPresented: $showingCreateGame) {
                CreateGameView { newGame in
                    games.append(newGame)
                }
            }
        }
    }
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

    var body: some View {
        NavigationView {
            Form {
                // Section for inviting friends
                Section(header: Text("Invite Friends")) {
                    Picker("Invite Option", selection: $inviteOption) {
                        ForEach(InviteOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if inviteOption == .viaLink {
                        Button(action: {
                            generateShareLink()
                        }) {
                            Text("Generate Shareable Link")
                        }
                        if !shareLink.isEmpty {
                            Text("Share this link with your friends:")
                                .font(.subheadline)
                            Text(shareLink)
                                .foregroundColor(.blue)
                                .textSelection(.enabled)
                        }
                    } else if inviteOption == .viaUsername {
                        TextField("Enter Friend's Username", text: $username)
                        Button(action: {
                            addUsername()
                        }) {
                            Text("Add Friend")
                        }.disabled(username.isEmpty)
                        if !invitedUsernames.isEmpty {
                            Text("Invited Friends: \(invitedUsernames.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section(header: Text("Game Mode")) {
                    Picker("Select Game Mode", selection: $selectedMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Game Details")) {
                    TextField("Name", text: $name)
                    if selectedMode == .custom {
                        if let location = locationManager.location {
                            Text("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        } else {
                            Text("No location data available. Enable location in settings.")
                        }
                        
                        
                        //if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                        //    Text("Location access is denied. Please enable it in settings.")
                        //        .foregroundColor(.red)
                        //} else if locationManager.location == nil {
                        //    HStack {
                        //        ProgressView()
                        //        Text("Fetching current location...")
                        //
                        //    }
                        //} else {
                        //    Text("Using your current location.")
                        //        .foregroundColor(.green)
                        //}
                    }
                }
            }
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
            }, trailing: Button("Add") {
                addGame()
                presentationMode.wrappedValue.dismiss()
            }.disabled(!canAddGame))
        }
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
            lat = 40.7128 // Example latitude (New York City)
            lon = -74.0060 // Example longitude
        case .spotMyOp:
            lat = 34.0522 // Example latitude (Los Angeles)
            lon = -118.2437 // Example longitude
        case .custom:
            if let userLocation = locationManager.location {
                lat = userLocation.coordinate.latitude
                lon = userLocation.coordinate.longitude
            } else {
                return // Location not available
            }
        }

        let newGame = Game(name: name, latitude: lat, longitude: lon, mode: selectedMode, invitedFriends: invitedUsernames)
        onAddGame(newGame)
    }

    func generateShareLink() {
        shareLink = "https://myapp.com/join?gameId=\(UUID().uuidString)"
    }

    func addUsername() {
        invitedUsernames.append(username)
        username = ""
    }
    //func updateAuthorizationStatus() {
    //    if let status = locationManager.authorizationStatus {
    //        switch status {
    //        case .authorizedWhenInUse, .authorizedAlways:
    //            isAuthorized = true
    //        case .denied, .restricted:
    //            isAuthorized = false
    //        default:
    //            isAuthorized = true
    //        }
    //    }
    //}
}

// MARK: - Preview

// Optional preview provider for SwiftUI previews
//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView(locationManager)
//    }
//}
