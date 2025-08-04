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
    ///
    /// - Returns: A view that presents the transcript debug menu as a sheet when `isPresented` is `true`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showDebugMenu = false
    ///     @State private var session = LanguageModelSession()
    ///     
    ///     var body: some View {
    ///         Button("Show Debug Menu") {
    ///             showDebugMenu = true
    ///         }
    ///         .transcriptDebugMenu(session, isPresented: $showDebugMenu)
    ///     }
    /// }
    /// ```
    func transcriptDebugMenu(_ session: LanguageModelSession, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            TranscriptDebugMenu(session: session)
        }
    }
}
