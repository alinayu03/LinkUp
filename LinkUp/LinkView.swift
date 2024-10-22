//
//  LinkView.swift
//  LinkUp
//
//  Created by Alina Yu on 10/22/24.
//

import SwiftUI

struct LinkView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Ready for your next adventure?")
                .font(.largeTitle)
                .bold()
                .padding()
            
            NavigationLink(destination: SuggestionsView()) {
                HStack {
                    Spacer()
                    Text("Link Up!")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .background(Color.blue)
                .cornerRadius(5)
                .padding()
            }
        }
        .padding()
    }
}
