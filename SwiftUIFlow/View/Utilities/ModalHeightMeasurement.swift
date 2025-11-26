//
//  ModalHeightMeasurement.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 26/11/25.
//

import SwiftUI

/// ViewModifier that automatically measures and reports content height
/// when the coordinator is presented as a modal.
///
/// This enables the content-sized sheet pattern to work automatically without
/// requiring client views to manually add measurement code.
struct ModalContentMeasurement: ViewModifier {
    let isModal: Bool
    @Binding var height: CGFloat?

    @State private var measuredHeight: CGFloat?

    func body(content: Content) -> some View {
        if isModal {
            content
                .onSizeChange { size in
                    measuredHeight = size.height
                }
                .preference(key: IdealHeightPreferenceKey.self, value: measuredHeight)
                .onChange(of: measuredHeight) { _, newValue in
                    height = newValue
                }
        } else {
            content
        }
    }
}
