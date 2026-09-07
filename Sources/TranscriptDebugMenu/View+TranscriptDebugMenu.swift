//
//  Created by Artem Novichkov on 04.08.2025.
//

import SwiftUI
import FoundationModels

public extension View {

    /// Presents a transcript debug menu as a sheet overlay.
    ///
    /// This view modifier provides a convenient way to present a `TranscriptDebugMenu`
    /// as a modal sheet that can be toggled on and off. The debug menu displays the
    /// transcript entries from the provided language model session in a navigable list.
    ///
    /// - Parameters:
    ///   - session: The `LanguageModelSession` whose transcript will be displayed in the debug menu.
    ///   - isPresented: A binding to a Boolean value that determines whether the debug menu is presented.
    ///   - configuration: Model-specific context metrics and menu configuration.
    ///     Defaults to an empty configuration, which omits context metrics without assuming a model.
    ///
    /// - Returns: A view that presents the transcript debug menu as a sheet when `isPresented` is `true`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showDebugMenu = false
    ///     private static let model = SystemLanguageModel.default
    ///     @State private var session = LanguageModelSession(model: ContentView.model)
    ///     
    ///     var body: some View {
    ///         Button("Show Debug Menu") {
    ///             showDebugMenu = true
    ///         }
    ///         .transcriptDebugMenu(
    ///             session,
    ///             isPresented: $showDebugMenu,
    ///             configuration: .systemModel(Self.model)
    ///         )
    ///     }
    /// }
    /// ```
    func transcriptDebugMenu(
        _ session: LanguageModelSession,
        isPresented: Binding<Bool>,
        configuration: TranscriptDebugMenu.Configuration = .init()
    ) -> some View {
        sheet(isPresented: isPresented) {
            TranscriptDebugMenu(session: session, configuration: configuration)
        }
    }
}
