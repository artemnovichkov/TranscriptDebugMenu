//
//  Created by Artem Novichkov on 24.07.2026.
//

import SwiftUI

/// Displays token usage against the model context window.
struct ContextSection: View {
    let tokenCount: Int
    let contextSize: Int

    var body: some View {
        Section("Context") {
            ProgressView(value: Double(tokenCount),
                         total: Double(contextSize)) {
                Text(TokenCounter.formattedCount(for: (tokenCount, contextSize)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    List {
        ContextSection(tokenCount: Mock.contextUsage.tokenCount,
                       contextSize: Mock.contextUsage.contextSize)
    }
}

#Preview("Near limit") {
    List {
        ContextSection(tokenCount: 3900, contextSize: 4096)
    }
}

#Preview("Empty") {
    List {
        ContextSection(tokenCount: 0, contextSize: 4096)
    }
}
