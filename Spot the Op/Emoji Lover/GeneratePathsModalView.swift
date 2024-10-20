import SwiftUI

struct GeneratePathsModalView: View {
    @Binding var showGeneratePathsModal: Bool // Control for showing and dismissing the modal

    var body: some View {
        VStack {
            Text("Generate Paths")
                .font(.largeTitle)
                .padding()

            Text("This is a placeholder for generating paths.")
                .padding()

            Button(action: {
                showGeneratePathsModal = false // Dismiss the modal
            }) {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
}
