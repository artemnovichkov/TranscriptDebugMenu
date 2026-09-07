//
//  Created by Artem Novichkov on 04.09.2026.
//

import Foundation
import FoundationModels
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum DebugJSON {
    static func prettyPrinted(_ content: GeneratedContent) -> String {
        prettyPrinted(jsonString: content.jsonString)
    }

    static func prettyPrinted<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return String(describing: value)
        }
        return string
    }

    static func prettyPrinted(jsonString: String) -> String {
        guard let source = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: source),
              let data = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
              ),
              let result = String(data: data, encoding: .utf8) else {
            return jsonString
        }
        return result
    }
}

enum DebugClipboard {
    static func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

struct DebugValueRow: View {
    let title: LocalizedStringKey
    let value: String

    init(_ title: LocalizedStringKey, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        Group {
            if usesExpandedLayout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    valueText
                        .font(value.contains("\n") ? .system(.body, design: .monospaced) : .body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LabeledContent {
                    valueText
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text(title)
                }
            }
        }
        .contextMenu {
            Button("Copy", systemImage: "document.on.document") {
                DebugClipboard.copy(value)
            }
        }
    }

    private var usesExpandedLayout: Bool {
        value.contains("\n") || value.count > 28
    }

    private var valueText: some View {
        Text(value)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
    }
}

extension GenerationOptions.SamplingMode {
    var debugDescription: String {
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else {
            return String(describing: self)
        }
        return kindDescription
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    private var kindDescription: String {
        switch kind {
        case .greedy:
            "Greedy"
        case .randomProbabilityThreshold(let threshold, let seed):
            "Random · top-p \(threshold)\(seedDescription(seed))"
        case .randomTopK(let topK, let seed):
            "Random · top-k \(topK)\(seedDescription(seed))"
        @unknown default:
            String(describing: kind)
        }
    }

    private func seedDescription(_ seed: UInt64?) -> String {
        seed.map { " · seed \($0)" } ?? ""
    }
}

extension GenerationOptions {
    var hasInspectableValues: Bool {
        if maximumResponseTokens != nil || temperature != nil || samplingMode != nil {
            return true
        }
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            return toolCallingMode != nil
        }
        return false
    }
}
