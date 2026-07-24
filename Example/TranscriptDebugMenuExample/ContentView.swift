//
//  Created by Artem Novichkov on 17.08.2025.
//

import SwiftUI

struct ContentView: View {
    private var scenarios: [ExampleScenario] {
        ExampleScenario.allCases.filter { scenario in
            if scenario.requiresOS27 {
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                    return true
                }
                return false
            }
            return true
        }
    }

    var body: some View {
        List(scenarios) { scenario in
            NavigationLink {
                ExampleSessionView(scenario: scenario)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scenario.title)
                        Text(scenario.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: scenario.systemImage)
                }
            }
        }
        .navigationTitle("Examples")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
