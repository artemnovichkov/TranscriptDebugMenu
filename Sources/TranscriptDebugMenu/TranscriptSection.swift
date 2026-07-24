//
//  Created by Artem Novichkov on 24.07.2026.
//

import SwiftUI
import FoundationModels

/// Lists transcript entries with accent colors, selection, and copy actions.
struct TranscriptSection: View {
    let transcript: Transcript
    var onSelect: (Transcript.Entry) -> Void = { _ in }
    var onCopy: (Transcript.Entry) -> Void = { _ in }

    var body: some View {
        Section("Transcript") {
            ForEach(transcript) { entry in
                TranscriptEntryRow(entry: entry)
                    .onTapGesture {
                        onSelect(entry)
                    }
                    .contextMenu {
                        Button("Copy") {
                            onCopy(entry)
                        }
                    }
            }
        }
    }
}

/// A single transcript entry row with accent indicator.
struct TranscriptEntryRow: View {
    let entry: Transcript.Entry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(entry.accentColor)
                .frame(width: 3)
            Text(entry.description)
        }
    }
}

#Preview {
    List {
        TranscriptSection(transcript: .mock)
    }
}

#Preview("Single entry") {
    List {
        TranscriptSection(transcript: Transcript(entries: [.promptMock]))
    }
}

#Preview("Empty") {
    List {
        TranscriptSection(transcript: Transcript())
    }
}

#Preview("Row") {
    List {
        TranscriptEntryRow(entry: .instructionsMock)
        TranscriptEntryRow(entry: .promptMock)
        TranscriptEntryRow(entry: .toolCallsMock)
        TranscriptEntryRow(entry: .toolOutputMock)
        TranscriptEntryRow(entry: .responseMock)
    }
}
