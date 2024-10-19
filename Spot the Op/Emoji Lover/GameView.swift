//
//  GameView.swift
//  Emoji Lover
//
//  Created by rakhi c on 10/19/24.
//

import SwiftUI
import GoogleMaps

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
        GMSServices.provideAPIKey("AIzaSyAYOhICkLqvWUF1FQeR9AJRmYSlPTg765s") // Replace with your actual API key

        // Set up the Google Map camera with the game's specific latitude, longitude, and zoom level
        let camera = GMSCameraPosition.camera(withLatitude: game.latitude, longitude: game.longitude, zoom: 10.0)

        // Initialize the GMSMapView using init()
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
        // You can update the map view here if needed
    }
}

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
            
            Spacer()
        }
        .padding()
        .navigationTitle(game.name)
    }
}
