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
    let isSmall: Bool

    init(title: String, description: String, detentType: String, color: Color, isSmall: Bool = false) {
        self.title = title
        self.description = description
        self.detentType = detentType
        self.color = color
        self.isSmall = isSmall
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)

            if !isSmall {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            }

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
