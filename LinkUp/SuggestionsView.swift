//
//  SuggestionsView.swift
//  LinkUp
//
//  Created by Alina Yu on 10/22/24.
//

import SwiftUI
import Firebase

// Define the User struct
struct User: Identifiable {
    var id: String { uid }
    let email: String
    let interests: String
    let location: String
    let name: String
    let outingSize: Int
    let uid: String
}

struct SuggestionsView: View {
    
    @State var activities = [String]() // List of activities from OpenAI
    @State var suggestedUsers = [User]() // List of suggested users
    @State var suggestionsStatusMessage = "Loading suggestions..."
    
    var body: some View {
        VStack(spacing: 16) {
            Text("We picked these out for you:")
                .font(.title)
                .bold()
            
            // Display the suggested activities
            ForEach(activities.indices, id: \.self) { index in
                Text("\(index + 1). \(activities[index])")
                    .padding()
                    .cornerRadius(5)
            }
            
            Text("Need a buddy?")
                .font(.title2)
                .bold()
                .padding(.top)
            
            // Display the suggested users
            ForEach(suggestedUsers, id: \.uid) { user in
                Text("\(user.name) - \(user.location)")
                    .padding()
                    .cornerRadius(5)
            }
            
            Text(suggestionsStatusMessage)
                .foregroundColor(.gray)
                .padding()
        }
        .padding()
        .onAppear {
            fetchSuggestions()
        }
    }
    
    // Fetching suggestions using OpenAI API
    private func fetchSuggestions() {
        fetchAllUsers { users in
            guard let currentUser = users.first(where: { $0.uid == FirebaseManager.shared.auth.currentUser?.uid }) else { return }
            
            getSuggestions(for: currentUser, allUsers: users) { result in
                DispatchQueue.main.async {
                    if result.contains("Failed") {
                        self.suggestionsStatusMessage = result
                    } else {
                        let lines = result.split(separator: "\n")
                        self.activities = Array(lines.prefix(3)).map { String($0) }
                        self.suggestedUsers = Array(users.prefix(3))
                        self.suggestionsStatusMessage = "Here are your suggestions!"
                    }
                }
            }
        }
    }
}

// The fetchAllUsers function to fetch user data from Firestore
func fetchAllUsers(completion: @escaping ([User]) -> Void) {
    FirebaseManager.shared.firestore.collection("users").getDocuments { snapshot, err in
        if let err = err {
            print("Failed to fetch users:", err)
            return
        }
        
        var users = [User]()
        
        snapshot?.documents.forEach { document in
            let data = document.data()
            let user = User(
                email: data["email"] as? String ?? "",
                interests: data["interests"] as? String ?? "",
                location: data["location"] as? String ?? "",
                name: data["name"] as? String ?? "",
                outingSize: data["outingSize"] as? Int ?? 0,
                uid: data["uid"] as? String ?? ""
            )
            users.append(user)
        }
        
        completion(users)
    }
}

// Prepare the prompt for OpenAI
func preparePrompt(for user: User, allUsers: [User]) -> String {
    let userDescriptions = allUsers.map { user in
        """
        Name: \(user.name)
        Email: \(user.email)
        Interests: \(user.interests)
        Location: \(user.location)
        Outing Size: \(user.outingSize)
        UID: \(user.uid)
        """
    }.joined(separator: "\n")
    
    let prompt = """
    Here is a user profile:
    
    Name: \(user.name)
    Interests: \(user.interests)
    Location: \(user.location)
    Outing Size: \(user.outingSize)
    
    Based on the above profile, suggest 3 activities this person would enjoy and recommend 3 other users they might like to hang out with, based on the following list of users:
    
    \(userDescriptions)
    
    Format your response by writing only the activity name, place and name, place. Do not number them.
    """
    
    return prompt
}

// Call OpenAI API to get suggestions
func getSuggestions(for user: User, allUsers: [User], completion: @escaping (String) -> Void) {
    let prompt = preparePrompt(for: user, allUsers: allUsers)
    
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String else {
        print("API Key not found")
        return
    }
    
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
        "model": "gpt-4o-mini",
        "messages": [
            ["role": "system", "content": "You are a helpful assistant."],
            ["role": "user", "content": prompt]
        ],
        "max_tokens": 300
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle errors in the network request
        if let error = error {
            print("Error fetching OpenAI response: \(error)")
            completion("Failed to fetch suggestions")
            return
        }
        
        guard let data = data else {
            print("No data received from OpenAI")
            completion("Failed to fetch suggestions")
            return
        }
        
        // Log the response for debugging
        if let jsonResponse = String(data: data, encoding: .utf8) {
            print("OpenAI raw response: \(jsonResponse)")
        }
        
        // Attempt to decode the OpenAI response
        do {
            let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            // Access the content from message in the response
            let suggestions = result.choices.first?.message.content ?? "No suggestions received"
            completion(suggestions)
        } catch {
            print("Error decoding OpenAI response: \(error)")
            completion("Failed to decode suggestions")
        }
    }.resume()
}



struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}
