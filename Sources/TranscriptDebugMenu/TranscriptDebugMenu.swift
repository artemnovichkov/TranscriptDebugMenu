//
//  Created by Artem Novichkov on 04.08.2025.
//

import SwiftUI
import FoundationModels

public struct TranscriptDebugMenu: View {

    let session: LanguageModelSession

    public init(session: LanguageModelSession) {
        self.session = session
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(session.transcript) { entry in
                    Text(entry.description)
                        .contextMenu {
                            Button("Copy") {
                                UIPasteboard.general.string = entry.description
                            }
                        }
                }
            }
            .navigationTitle("Transcript")
        }
    }
}

#Preview {
    @Previewable @State var isPresented = false
    @Previewable @State var session = LanguageModelSession(transcript: .mock)

    Button("Show Transcript Menu") {
        isPresented.toggle()
    }
    .transcriptDebugMenu(session, isPresented: $isPresented)
}
