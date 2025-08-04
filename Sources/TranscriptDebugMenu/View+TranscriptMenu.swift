//
//  Created by Artem Novichkov on 04.08.2025.
//

import SwiftUI
import FoundationModels

public extension View {

    func transcriptMenu(session: LanguageModelSession, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            LanguageModelSessionTranscriptMenu(session: session)
        }
    }
}
