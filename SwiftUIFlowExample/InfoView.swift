//
//  InfoView.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 9/11/25.
//

import SwiftUI
import SwiftUIFlow

struct InfoView: View {
    @Environment(\.navigationBackAction) var backAction

    let title: String
    let description: String
    let detentType: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Detent: \(detentType)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .navigationTitle("Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    backAction?()
                }
                .foregroundColor(color)
            }
        }
    }
}
