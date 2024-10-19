//
//  AuthView.swift
//  Emoji Lover
//
//  Created by rakhi c on 10/19/24.
//

import SwiftUI

struct AuthView: View {
    @State private var isSignUp = false
    @EnvironmentObject var appController: AppController
  var body: some View {
      
      VStack{
          Spacer()
          TextField("Email", text: $appController.email) // Bind directly to the email property
                          .textFieldStyle(RoundedBorderTextFieldStyle())
                          .padding()
          SecureField("Password", text: $appController.password) // Bind directly to the email property
                          .textFieldStyle(RoundedBorderTextFieldStyle())
                          .padding()
          Button(action: {
              authenticate() // Call the function inside a closure
          }, label: {
              HStack {
                  Spacer()
                  Text("\(isSignUp ? "Sign Up" : "Sign In")")
                  Spacer()
              }
          })
          .buttonStyle(.borderedProminent)
          
          Button(action: {
              isSignUp.toggle() // Call toggle() inside a closure
          }) {
              Text(isSignUp ? "I already have an account" : "I don't have an account")
          }.padding(.top)
          
      }
      .padding()
//    Text("Auth Screen")
//      .font(.largeTitle)
//      .padding()
  }
    func authenticate() {
        isSignUp ? signUp() : signIn()
    }
    
    func signUp() {
        Task {
            do {
                try await appController.signUp()
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    func signIn() {
        
        Task {
            do {
                try await appController.signIn()
                
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
}

#Preview {
    AuthView()
}
