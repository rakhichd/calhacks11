import SwiftUI
import GoogleGenerativeAI

// Updated PredictiveDataView that uses spottedHistory from Game model
struct PredictiveDataView: View {
    var game: Game  // Pass the Game instance containing spotted locations
    
    @State private var prompt: String = "Predict the next event based on these coordinates:"
    @State private var generatedText: String = ""
    
    var body: some View {
        NavigationView {
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

                Section(header: Text("Generated Predictive Data")) {
                    Text(generatedText)
                        .padding()
                }
            }
            .navigationTitle("Predictive Data Generator")
        }
    }

    // Function to generate predictive content based on spotted history
    func generateContent() async {
        let spottedHistoryStrings = game.spottedHistory.map {
            "Lat: \($0.latitude), Long: \($0.longitude), Time: \($0.timestamp), Description: \($0.personSpotted)"
        }
        let dataInput = spottedHistoryStrings.joined(separator: "\n")
        
        let fullPrompt = """
        \(prompt)

        Given the following observations:

        Coordinates:
        \(dataInput)

        Please generate the possible 3 locations in latitude and longitude format where the following person is most likely to show up at this time frame. Return them as an array in the format: "{person} is most likely right now to show up at your location {lat} {long}". No explanation, just the list.
        """

        do {
            let model = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: "AIzaSyDs9Oqb-kjqrh4cd5fsQhqBgAmW2rYEqo4") // Replace with your actual API key
            let response = try await model.generateContent(fullPrompt)
            
            // Extract the generated text from the response
            if let candidate = response.candidates.first,
               let generatedTextPart = candidate.content.parts.first?.text {
                // Here we handle the response as plain text without trying to interpret it as JSON
                generatedText = generatedTextPart
            } else {
                generatedText = "No prediction generated"
            }
        } catch {
            print("Error generating predictive data: \(error)")
            generatedText = "Error occurred"
        }
    }
}

struct PredictiveDataView_Previews: PreviewProvider {
    static var previews: some View {
        PredictiveDataView(game: Game(name: "UC Berkeley", latitude: 37.8719, longitude: -122.2585))
    }
}
