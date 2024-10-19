import SwiftUI

struct SettingsView: View {
    @State private var email: String = "user@example.com"
    @State private var newPassword: String = ""
    @State private var enableNotifications: Bool = true
    @State private var enableLocationTracking: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // Email section
                Section(header: Text("Email")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        
                }
                
                // Password section
                Section(header: Text("Change Password")) {
                    SecureField("New Password", text: $newPassword)
                        
                    Button(action: {
                        // Add functionality to change password
                        print("Password changed")
                    }) {
                        Text("Update Password")
                            .foregroundColor(.blue)
                    }
                }
                
                // Notification Settings section
                Section(header: Text("Notifications")) {
                    Toggle(isOn: $enableNotifications) {
                        Text("Enable Notifications")
                    }
                }
                
                // Location Tracking section
                Section(header: Text("Location Tracking")) {
                    Toggle(isOn: $enableLocationTracking) {
                        Text("Enable Location Tracking")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
