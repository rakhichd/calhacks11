//
//  CreateGameView.swift
//  Emoji Lover
//
//  Created by rakhi c on 10/19/24.
//

import SwiftUI

// CreateGameView allows the user to input new game details
struct CreateGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var latitudeText = ""
    @State private var longitudeText = ""

    var onCreate: (Game) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Details")) {
                    TextField("Name", text: $name)
                    TextField("Latitude", text: $latitudeText)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitudeText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Create Game")
            .navigationBarItems(leading:
                Button("Cancel") {
                    // Dismiss the sheet without saving
                    presentationMode.wrappedValue.dismiss()
                },
                trailing:
                Button("Save") {
                    // Validate inputs and create a new game
                    if let latitude = Double(latitudeText),
                       let longitude = Double(longitudeText),
                       !name.isEmpty {
                        let newGame = Game(name: name, latitude: latitude, longitude: longitude)
                        onCreate(newGame)
                        // Dismiss the sheet after saving
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(name.isEmpty || Double(latitudeText) == nil || Double(longitudeText) == nil)
            )
        }
    }
}
