//
//  Created by Artem Novichkov on 24.07.2026.
//

import SwiftUI
import FoundationModels

/// Displays session token usage breakdown (input, cached, output, reasoning).
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct UsageSection: View {
    let usage: LanguageModelSession.Usage
    @State private var isExpanded = false

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                LabeledContent("Input", value: usage.input.totalTokenCount, format: .number)
                LabeledContent("Cached input", value: usage.input.cachedTokenCount, format: .number)
                LabeledContent("Output", value: usage.output.totalTokenCount, format: .number)
                LabeledContent("Reasoning", value: usage.output.reasoningTokenCount, format: .number)
            } label: {
                Text("Total: ^[\(usage.totalTokenCount) token](inflect: true)")
            }
        } header: {
            Text("Usage")
        }
    }
}

#Preview {
    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
        List {
            UsageSection(usage: .mock)
        }
    }
}
