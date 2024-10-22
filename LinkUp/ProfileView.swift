//
//  ProfileView.swift
//  LinkUp
//
//  Created by Alina Yu on 10/22/24.
//

import SwiftUI
import Firebase

struct ProfileView: View {
    
    @State var name = ""
    @State var location = ""
    @State var interests = ""
    @State var outingSize = 2 // Default outing size
    @State var saveStatusMessage = ""
    @State var isProfileSaved = false // To navigate after saving profile
    
    var body: some View {
        VStack(spacing: 16) {
            
            Text("Create Your Profile")
                .font(.largeTitle)
                .bold()
            
            TextField("Name", text: $name)
                .padding(12)
                .background(Color.white)
                .cornerRadius(5)
            
            TextField("Location", text: $location)
                .padding(12)
                .background(Color.white)
                .cornerRadius(5)
            
            TextField("Interests", text: $interests)
                .padding(12)
                .background(Color.white)
                .cornerRadius(5)
            
            Stepper(value: $outingSize, in: 1...10) {
                Text("Outing Size: \(outingSize)")
            }
            .padding(12)
            
            Button(action: {
                saveProfile()
            }) {
                HStack {
                    Spacer()
                    Text("Save Profile")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .background(Color.blue)
                .cornerRadius(5)
            }
            
            Text(self.saveStatusMessage)
                .foregroundColor(.red)
            
            NavigationLink(destination: LinkView(), isActive: $isProfileSaved) {
                EmptyView()
            }
        }
        .padding()
    }
    
    private func saveProfile() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.saveStatusMessage = "User not logged in."
            return
        }
        
        let profileData = [
            "name": self.name,
            "location": self.location,
            "interests": self.interests,
            "outingSize": self.outingSize
        ] as [String : Any]
        
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(profileData, merge: true) { err in
            if let err = err {
                print("Failed to save profile data:", err)
                self.saveStatusMessage = "Failed to save profile data: \(err)"
                return
            }
            
            print("Profile successfully saved!")
            self.saveStatusMessage = "Profile successfully saved!"
            self.isProfileSaved = true // Navigate to LinkView
        }
    }
}
