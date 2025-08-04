//
//  Created by Artem Novichkov on 04.08.2025.
//

import SwiftUI
import FoundationModels

public extension View {

    func transcriptDebugMenu(_ session: LanguageModelSession, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            TranscriptDebugMenu(session: session)
        }
    }
}
