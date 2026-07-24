//
//  Created by Artem Novichkov on 21.07.2026.
//

import SwiftUI
import FoundationModels
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Transcript.Entry {
    var title: String {
        switch self {
        case .instructions: return "Instructions"
        case .prompt: return "Prompt"
        case .response: return "Response"
        case .toolCalls: return "Tool Calls"
        case .toolOutput: return "Tool Output"
        default:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning = self {
                return "Reasoning"
            }
            return "Unknown"
        }
    }

    var preview: String {
        switch self {
        case .instructions(let v): return Self.text(from: v.segments)
        case .prompt(let v): return Self.text(from: v.segments)
        case .response(let v): return Self.text(from: v.segments)
        case .toolOutput(let v): return Self.text(from: v.segments)
        case .toolCalls(let v): return v.map(\.toolName).joined(separator: ", ")
        default:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning(let v) = self {
                return Self.text(from: v.segments)
            }
            return ""
        }
    }

    private static func text(from segments: [Transcript.Segment]) -> String {
        segments.compactMap { segment -> String? in
            switch segment {
            case .text(let t): return t.content
            case .structure(let s): return s.source
            default:
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .attachment(let a) = segment {
                    return a.label
                }
                return nil
            }
        }.joined(separator: " ")
    }

    /// System accent color matching the entry type. Adapts to light/dark appearance.
    var accentColor: Color {
        switch self {
        case .instructions:
            return .systemGray
        case .prompt:
            return .systemBlue
        case .response:
            return .systemGreen
        case .toolCalls:
            return .systemOrange
        case .toolOutput:
            return .systemIndigo
        default:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning = self {
                return .systemPurple
            }
            return Color.secondary
        }
    }
}

private extension Color {
    #if canImport(UIKit)
    static let systemGray = Color(uiColor: .systemGray)
    static let systemBlue = Color(uiColor: .systemBlue)
    static let systemGreen = Color(uiColor: .systemGreen)
    static let systemOrange = Color(uiColor: .systemOrange)
    static let systemIndigo = Color(uiColor: .systemIndigo)
    static let systemPurple = Color(uiColor: .systemPurple)
    #elseif canImport(AppKit)
    static let systemGray = Color(nsColor: .systemGray)
    static let systemBlue = Color(nsColor: .systemBlue)
    static let systemGreen = Color(nsColor: .systemGreen)
    static let systemOrange = Color(nsColor: .systemOrange)
    static let systemIndigo = Color(nsColor: .systemIndigo)
    static let systemPurple = Color(nsColor: .systemPurple)
    #endif
}
