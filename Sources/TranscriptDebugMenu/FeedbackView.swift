//
//  Created by Artem Novichkov on 04.09.2026.
//

import FoundationModels
import SwiftUI

struct FeedbackDraft: Equatable {
    enum SentimentSelection: String, CaseIterable, Identifiable {
        case unspecified
        case positive
        case neutral
        case negative

        var id: Self { self }

        var title: String {
            switch self {
            case .unspecified: "Unspecified"
            case .positive: "Positive"
            case .neutral: "Neutral"
            case .negative: "Negative"
            }
        }

        var value: LanguageModelFeedback.Sentiment? {
            switch self {
            case .unspecified: nil
            case .positive: .positive
            case .neutral: .neutral
            case .negative: .negative
            }
        }
    }

    var sentiment: SentimentSelection = .unspecified
    var issueDrafts: [FeedbackIssueDraft] = LanguageModelFeedback.Issue.Category.allCases.map {
        FeedbackIssueDraft(category: $0)
    }
    var desiredResponseText = ""

    var issues: [LanguageModelFeedback.Issue] {
        issueDrafts.compactMap { draft in
            guard draft.isSelected else { return nil }
            let explanation = draft.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
            return LanguageModelFeedback.Issue(
                category: draft.category,
                explanation: explanation.isEmpty ? nil : explanation
            )
        }
    }

    var desiredResponse: String? {
        let value = desiredResponseText.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

struct FeedbackIssueDraft: Identifiable, Equatable {
    let category: LanguageModelFeedback.Issue.Category
    var isSelected = false
    var explanation = ""

    var id: String { category.title }
}

private extension LanguageModelFeedback.Issue.Category {
    var title: String {
        switch self {
        case .unhelpful: "Unhelpful"
        case .tooVerbose: "Too Verbose"
        case .didNotFollowInstructions: "Did Not Follow Instructions"
        case .incorrect: "Incorrect"
        case .stereotypeOrBias: "Stereotype or Bias"
        case .suggestiveOrSexual: "Suggestive or Sexual"
        case .vulgarOrOffensive: "Vulgar or Offensive"
        case .triggeredGuardrailUnexpectedly: "Unexpected Guardrail"
        @unknown default: String(describing: self)
        }
    }
}

struct FeedbackView: View {
    @Binding var draft: FeedbackDraft
    let attachmentURL: URL?
    var onRetry: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if attachmentURL == nil {
                    Section {
                        Text("Couldn't save the feedback attachment. Try again to enable sharing.")
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            onRetry()
                        }
                    }
                }
                Section("Sentiment") {
                    Picker("Sentiment", selection: $draft.sentiment) {
                        ForEach(FeedbackDraft.SentimentSelection.allCases) { sentiment in
                            Text(sentiment.title).tag(sentiment)
                        }
                    }
                }

                Section("Issues") {
                    ForEach($draft.issueDrafts) { $issue in
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(issue.category.title, isOn: $issue.isSelected)
                            if issue.isSelected {
                                TextField("Explanation (optional)", text: $issue.explanation, axis: .vertical)
                                    .lineLimit(2...5)
                            }
                        }
                    }
                }

                Section {
                    TextEditor(text: $draft.desiredResponseText)
                        .frame(minHeight: 120)
                } header: {
                    Text("Desired Response")
                } footer: {
                    Text("Add the response you expected the model to produce.")
                }
            }
            .navigationTitle("Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if let attachmentURL {
                        ShareLink(item: attachmentURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var draft = FeedbackDraft()
    FeedbackView(draft: $draft, attachmentURL: nil)
}

#Preview("Feedback Draft") {
    @Previewable @State var draft: FeedbackDraft = {
        var draft = FeedbackDraft()
        draft.sentiment = .negative
        draft.issueDrafts[2].isSelected = true
        draft.issueDrafts[2].explanation = "The response didn't follow the requested haiku format."
        draft.desiredResponseText = "A three-line haiku about Swift."
        return draft
    }()
    FeedbackView(draft: $draft, attachmentURL: URL(fileURLWithPath: "/tmp/preview.feedback.json"))
}
