//
//  CreateGameView.swift
//  Emoji Lover
//
//  Created by rakhi c on 10/19/24.
//

import SwiftUI

// CreateGameView allows the user to input new game details
//struct CreateGameView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @State private var name = ""
//    @State private var latitudeText = ""
//    @State private var longitudeText = ""
//
////    var onCreate: (Game) -> Void
////
////    var body: some View {
////        NavigationView {
////            Form {
////                Section(header: Text("Game Details")) {
////                    TextField("Name", text: $name)
////                    TextField("Latitude", text: $latitudeText)
////                        .keyboardType(.decimalPad)
////                    TextField("Longitude", text: $longitudeText)
////                        .keyboardType(.decimalPad)
////                }
////            }
////            .navigationTitle("Create Game")
////            .navigationBarItems(leading:
////                Button("Cancel") {
////                    // Dismiss the sheet without saving
////                    presentationMode.wrappedValue.dismiss()
////                },
////                trailing:
////                Button("Save") {
////                    // Validate inputs and create a new game
////                    if let latitude = Double(latitudeText),
////                       let longitude = Double(longitudeText),
////                       !name.isEmpty {
////                        let newGame = Game(name: name, latitude: latitude, longitude: longitude)
////                        onCreate(newGame)
////                        // Dismiss the sheet after saving
////                        presentationMode.wrappedValue.dismiss()
////                    }
////                }
////                .disabled(name.isEmpty || Double(latitudeText) == nil || Double(longitudeText) == nil)
////            )
////        }
////    }
////}
//
//import FirebaseFirestore
//import SwiftUI
//
//class GameViewModel: ObservableObject {
//    @Published var games: [Game] = []
//    private var db = Firestore.firestore()
//
//    // Fetch games with a completion handler
//    func fetchGames(completion: @escaping ([Game]) -> Void) {
//        db.collection("games").getDocuments { (snapshot, error) in
//            if let error = error {
//                print("Error fetching games: \(error.localizedDescription)")
//                completion([]) // Return empty array in case of error
//                return
//            }
//
//            guard let documents = snapshot?.documents else {
//                print("No games found")
//                completion([]) // Return empty array if no games are found
//                return
//            }
//
//            let fetchedGames: [Game] = documents.compactMap { doc -> Game? in
//                let data = doc.data()
//                print(data)
//                let id = doc.documentID
//                let name = data["gameName"] as? String ?? "Unknown Game"
//                let latitude = data["latitude"] as? Double ?? 0.0
//                let longitude = data["longitude"] as? Double ?? 0.0
//                
//                // Parse GameMode safely (assuming it's stored as a string)
//                let modeString = data["mode"] as? String ?? ""
//                let mode = GameMode(rawValue: modeString) ?? nil // Add .unknown or other default case
//                
//                let invitedFriends = data["invitedFriends"] as? [String] ?? []
//
//                // Parse SpottedHistory array of dictionaries
//                let spottedHistoryData = data["spottedHistory"] as? [[String: Any]] ?? []
//                let spottedHistory = spottedHistoryData.compactMap { dict -> SpottedLocation? in
//                    guard
//                        let latitude = dict["latitude"] as? Double,
//                        let longitude = dict["longitude"] as? Double,
//                        let personSpotted = dict["personSpotted"] as? String,
//                        let timestamp = dict["timestamp"] as? Timestamp
//                    else {
//                        return nil
//                    }
//                    return SpottedLocation(
//                        latitude: latitude,
//                        longitude: longitude,
//                        timestamp: timestamp.dateValue(),
//                        personSpotted: personSpotted
//                    )
////                }
////
////                return Game(
////                    id: id,
////                    name: name,
////                    latitude: latitude,
////                    longitude: longitude,
////                    mode: mode,
////                    invitedFriends: invitedFriends,
////                    spottedHistory: spottedHistory
////                )
////            }
////
////            self.games = fetchedGames // Update the @Published games array
////            completion(fetchedGames) // Pass the fetched games to the completion handler
////        }
////    }
////}
//
//
//// Place this outside of HomeView or in a separate file.
//struct CreateGameView: View {
//    @Environment(\.presentationMode) var presentationMode
//    var onAddGame: (Game) -> Void
//
//    @State private var name = ""
//    @State private var selectedMode: GameMode = .spotMyEx
//    @StateObject private var locationManager = LocationManager()
//
//    // Inviting friends
//    @State private var inviteOption: InviteOption = .none
//    @State private var shareLink: String = ""
//    @State private var username: String = ""
//    @State private var invitedUsernames: [String] = []
//
//    private var db = Firestore.firestore()
//
//    init(onAddGame: @escaping (Game) -> Void) {
//        self.onAddGame = onAddGame
//    }
//
//    var body: some View {
//        // Your existing code inside CreateGameView...
//    }
//
//    // Your functions inside CreateGameView (addGame, generateShareLink, etc.)...
//
//}
