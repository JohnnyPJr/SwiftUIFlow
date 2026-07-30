//
//  ModalDetentPresentationModifier.swift
//  SwiftUIFlow
//
//  Created by Codex on 30/7/26.
//

import SwiftUI

/// Shared modal detent presentation behavior for all coordinator presentation paths.
struct ModalDetentPresentationModifier<R: Route>: ViewModifier {
    @ObservedObject var router: Router<R>

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(IdealHeightPreferenceKey.self) { height in
                router.updateModalIdealHeight(height)
            }
            .onPreferenceChange(MinHeightPreferenceKey.self) { height in
                router.updateModalMinHeight(height)
            }
            .presentationDetents(presentationDetentsSet,
                                 selection: presentationDetentSelection)
    }

    /// Convert modal detent configuration to SwiftUI PresentationDetent set.
    private var presentationDetentsSet: Set<PresentationDetent> {
        guard let config = router.state.modalDetentConfiguration else {
            return [.large]
        }

        return Set(config.detents.map { config.toPresentationDetent($0) })
    }

    /// Create a binding for the currently selected presentation detent.
    private var presentationDetentSelection: Binding<PresentationDetent> {
        Binding(get: {
                    guard let config = router.state.modalDetentConfiguration,
                          let selected = config.selectedDetent
                    else {
                        return .large
                    }
                    return config.toPresentationDetent(selected)
                },
                set: { newDetent in
                    guard let config = router.state.modalDetentConfiguration else { return }
                    let modalDetent = config.fromPresentationDetent(newDetent)
                    router.updateModalSelectedDetent(modalDetent)
                })
    }
}

extension View {
    /// Applies SwiftUIFlow's shared modal detent behavior to a presented coordinator view.
    func modalDetents(router: Router<some Route>) -> some View {
        modifier(ModalDetentPresentationModifier(router: router))
    }
}

extension Router {
    /// Whether the current modal configuration should render with `fullScreenCover`.
    var shouldUseFullScreenCoverForCurrentModal: Bool {
        state.modalDetentConfiguration?.shouldUseFullScreenCover ?? false
    }
}
