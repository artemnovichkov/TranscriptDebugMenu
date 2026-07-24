//
//  Created by Artem Novichkov on 24.07.2026.
//

import FoundationModels
import Observation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@Observable
final class HaikuProfileState {
    enum Mode: String, CaseIterable, Identifiable {
        case freeform
        case withTools

        var id: String { rawValue }

        var title: String {
            switch self {
            case .freeform: "Freeform"
            case .withTools: "With Tools"
            }
        }
    }

    var mode: Mode = .withTools
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct HaikuProfile: LanguageModelSession.DynamicProfile {
    let state: HaikuProfileState

    var body: some LanguageModelSession.DynamicProfile {
        switch state.mode {
        case .freeform:
            Profile {
                Instructions {
                    """
                    You're a helpful assistant that writes short poems.
                    Keep answers brief and poetic.
                    """
                }
            }
            .temperature(0.9)

        case .withTools:
            Profile {
                Instructions {
                    """
                    You're a helpful assistant that generates haiku.
                    Always call generateMood first, then write a haiku in that mood.
                    """
                }
                MoodTool()
            }
            .temperature(0.6)
        }
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ContentTaggingProfile: LanguageModelSession.DynamicProfile {
    var body: some LanguageModelSession.DynamicProfile {
        Profile {
            Instructions {
                """
                Extract the most important topics from the given text.
                Prefer concise topic labels.
                """
            }
        }
        .model(SystemLanguageModel(useCase: .contentTagging))
        .temperature(0.2)
    }
}
