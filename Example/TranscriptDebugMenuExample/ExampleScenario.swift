//
//  Created by Artem Novichkov on 24.07.2026.
//

import FoundationModels
import SwiftUI

enum ExampleScenario: String, CaseIterable, Identifiable {
    case noTools
    case withTools
    case multiTools
    case structured
    case contentTagging
    case permissiveGuardrails
    case dynamicProfile
    case profileWithModelSwitch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noTools: "No Tools"
        case .withTools: "With Tools"
        case .multiTools: "Multiple Tools"
        case .structured: "Structured Output"
        case .contentTagging: "Content Tagging Model"
        case .permissiveGuardrails: "Permissive Guardrails"
        case .dynamicProfile: "Dynamic Profile"
        case .profileWithModelSwitch: "Profile + Tagging Model"
        }
    }

    var subtitle: String {
        switch self {
        case .noTools:
            "Default model, instructions only"
        case .withTools:
            "MoodTool + haiku instructions"
        case .multiTools:
            "MoodTool + PoemStyleTool"
        case .structured:
            "Generable Haiku, no tools"
        case .contentTagging:
            "SystemLanguageModel(useCase: .contentTagging)"
        case .permissiveGuardrails:
            "Default model with permissive guardrails"
        case .dynamicProfile:
            "LanguageModelSession(profile:) freeform / tools"
        case .profileWithModelSwitch:
            "Profile bound to content tagging model"
        }
    }

    var systemImage: String {
        switch self {
        case .noTools: "text.bubble"
        case .withTools: "wrench.and.screwdriver"
        case .multiTools: "wrench.and.screwdriver.fill"
        case .structured: "curlybraces"
        case .contentTagging: "tag"
        case .permissiveGuardrails: "shield.lefthalf.filled"
        case .dynamicProfile: "person.crop.rectangle.stack"
        case .profileWithModelSwitch: "arrow.triangle.branch"
        }
    }

    var requiresOS27: Bool {
        switch self {
        case .dynamicProfile, .profileWithModelSwitch:
            true
        default:
            false
        }
    }

    var prompt: String {
        switch self {
        case .noTools:
            "Write a short haiku about Swift concurrency."
        case .withTools:
            "Generate a haiku about Swift. Use the mood tool first."
        case .multiTools:
            "Write a short poem about debugging. Pick a style and a mood first."
        case .structured:
            "Generate a haiku about Xcode."
        case .contentTagging:
            """
            Apple Intelligence brings on-device foundation models to apps. \
            Developers can call tools, stream responses, and inspect transcripts \
            while keeping user data private.
            """
        case .permissiveGuardrails:
            "Rewrite this more clearly: The app crashed when the user tapped save."
        case .dynamicProfile:
            "Write a short poem about code review."
        case .profileWithModelSwitch:
            """
            Foundation Models sessions keep a transcript of instructions, prompts, \
            tool calls, and responses. Dynamic profiles switch models and tools \
            based on app state without losing history.
            """
        }
    }
}
