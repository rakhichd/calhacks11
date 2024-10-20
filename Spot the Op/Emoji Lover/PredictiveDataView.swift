import SwiftUI
import GoogleGenerativeAI
import GoogleMaps
import GoogleMapsUtils
import CoreLocation

// Updated PredictiveDataView that uses spottedHistory from Game model
struct PredictiveDataView: View {
    var game: Game  // Pass the Game instance containing spotted locations
    
    @State private var prompt: String = "Predict the next likely locations based on these coordinates:"
    @State private var generatedText: String = ""
    @State private var predictedLocations: [(person: String, location: CLLocationCoordinate2D)] = []  // Store predicted coordinates with persons
    @State private var predictedSentences: [String] = []  // Store generated sentences
    @State private var showHeatmap = false  // Toggle heatmap display

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Prompt")) {
                        TextField("Enter your prompt", text: $prompt)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }

                    Button(action: {
                        Task {
                            await generateContent()
                        }
                    }) {
                        Text("Generate Predictive Data")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    // Display the generated predictive data sentences
                    if !predictedSentences.isEmpty {
                        Section(header: Text("Generated Predictive Data")) {
                            ForEach(predictedSentences, id: \.self) { sentence in
                                Text(sentence)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // Show heatmap toggle button if there are predicted locations
                    if !predictedLocations.isEmpty {
                        Button(action: {
                            showHeatmap.toggle()
                        }) {
                            Text(showHeatmap ? "Hide Areas of Caution" : "Show Areas of Caution")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                // Show the heatmap if toggle is true
                if showHeatmap {
                    HeatmapView(locations: predictedLocations.map { $0.location })
                        .frame(height: 300)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .navigationTitle("Predictive Data Generator")
        }
    }

    // Function to generate predictive content based on spotted history
    func generateContent() async {
        let spottedHistoryStrings = game.spottedHistory.map {
            "Location: Lat: \($0.latitude), Long: \($0.longitude), Time: \($0.timestamp), Person: \($0.personSpotted)"
        }
        let dataInput = spottedHistoryStrings.joined(separator: "\n")
        
        let fullPrompt = """
        \(prompt)

        Given the following observations of people's locations:

        \(dataInput)

        Based on these observations, generate the three most likely future locations (in latitude and longitude format) for the next spotting. Return them as an array in the format: "{person} is most likely right now to show up at your location {lat} {long}". Provide no explanations, only the list.
        """

        do {
            let model = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: "AIzaSyDs9Oqb-kjqrh4cd5fsQhqBgAmW2rYEqo4") // Replace with your actual API key
            let response = try await model.generateContent(fullPrompt)
            
            // Extract the generated text from the response
            if let candidate = response.candidates.first,
               let generatedTextPart = candidate.content.parts.first?.text {
                generatedText = generatedTextPart
                parsePredictedLocations(from: generatedTextPart)
            } else {
                generatedText = "No prediction generated"
                predictedLocations = []  // Clear predictions
            }
        } catch {
            print("Error generating predictive data: \(error)")
            generatedText = "Error occurred"
            predictedLocations = []  // Clear predictions
        }
    }

    // Function to parse predicted locations from the generated text
    func parsePredictedLocations(from text: String) {
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        // Extract the person name and latitude/longitude from each sentence
        predictedLocations = lines.compactMap { line in
            let regex = try! NSRegularExpression(pattern: #"([-+]?\d{1,2}\.\d+)\s([-+]?\d{1,3}\.\d+)"#, options: [])
            if let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)),
               let latRange = Range(match.range(at: 1), in: line),
               let lonRange = Range(match.range(at: 2), in: line),
               let latitude = Double(line[latRange]),
               let longitude = Double(line[lonRange]) {
                let person = line.components(separatedBy: " ").first ?? "Someone"
                return (person: person, location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
            return nil
        }
        
        predictedSentences = lines  // Store the original sentences
        
        // Convert lat/long to readable city names in the original sentences
        reverseGeocodeLocations()
    }

    // Function to convert lat/long to readable city names and update sentences
    func reverseGeocodeLocations() {
        let geocoder = CLGeocoder()
        let group = DispatchGroup()
        predictedSentences = [] // Clear existing sentences

        for (person, location) in predictedLocations {
            group.enter()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, error in
                defer { group.leave() }
                
                if let city = placemarks?.first?.locality {
                    let updatedSentence = "\(person) is most likely right now to show up in \(city)."
                    predictedSentences.append(updatedSentence)
                } else {
                    // Fallback to lat/long if city name can't be found
                    let fallbackSentence = "\(person) is most likely right now to show up at your location \(location.latitude), \(location.longitude)."
                    predictedSentences.append(fallbackSentence)
                }
            }
        }

        group.notify(queue: .main) {
            // Refresh the UI when geocoding is complete
        }
    }
}

// MARK: - Heatmap View for predicted locations

struct HeatmapView: UIViewRepresentable {
    var locations: [CLLocationCoordinate2D]

    class Coordinator: NSObject, GMSMapViewDelegate {
        var heatmapLayer: GMUHeatmapTileLayer?

        func addHeatMap(mapView: GMSMapView, locations: [CLLocationCoordinate2D]) {
            var list = [GMUWeightedLatLng]()
            for location in locations {
                let coords = GMUWeightedLatLng(coordinate: location, intensity: 1.0)
                list.append(coords)
            }

            let heatmapLayer = GMUHeatmapTileLayer()
            heatmapLayer.weightedData = list
            heatmapLayer.radius = 80
            heatmapLayer.map = mapView
            self.heatmapLayer = heatmapLayer
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey("AIzaSyAYOhICkLqvWUF1FQeR9AJRmYSlPTg765s") // Replace with your Google Maps API key
        
        let camera = GMSCameraPosition.camera(withLatitude: 37.8719, longitude: -122.2585, zoom: 10.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        // Add the heatmap with the predicted locations
        context.coordinator.addHeatMap(mapView: mapView, locations: locations)

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.heatmapLayer?.map = nil  // Remove the old heatmap layer
        context.coordinator.addHeatMap(mapView: uiView, locations: locations)  // Add new heatmap layer
    }
}

// MARK: - Preview

struct PredictiveDataView_Previews: PreviewProvider {
    static var previews: some View {
        PredictiveDataView(game: Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585))
    }
}
