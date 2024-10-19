//
//  ProfileView.swift
//  Spot the Op
//
//  Created by rakhi c on 10/19/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appController: AppController
  var body: some View {
      
      VStack {
          Button("Logout") {
              do {
                  try appController.signOut()
              } catch {
                  print(error.localizedDescription)
              }
          }
      }
      
      
      
    Text("Profile Screen")
      .font(.largeTitle)
      .padding()
  }
}

#Preview {
    ProfileView()
}
