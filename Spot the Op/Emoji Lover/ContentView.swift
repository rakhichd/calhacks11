import SwiftUI
import GoogleMaps

// Create a UIViewRepresentable to wrap the GMSMapView
struct GoogleMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> GMSMapView {
        // Provide the API Key for Google Maps services
        GMSServices.provideAPIKey("AIzaSyAYOhICkLqvWUF1FQeR9AJRmYSlPTg765s") // Replace with your API key
        
        // Set up the Google Map camera with a specific latitude, longitude, and zoom level
        let camera = GMSCameraPosition.camera(withLatitude: 37.7749, longitude: -122.4194, zoom: 10.0)
        
        // Initialize the GMSMapView using init()
        let mapView = GMSMapView()
        mapView.camera = camera
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // You can update the map view here if needed
    }
}

// SwiftUI ContentView to display the map
struct ContentView: View {
    var body: some View {
        GoogleMapView()
            .edgesIgnoringSafeArea(.all) // Makes the map fullscreen, ignoring safe area
    }
}

// SwiftUI App structure
@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
