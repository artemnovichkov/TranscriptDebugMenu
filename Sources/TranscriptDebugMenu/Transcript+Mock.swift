//
//  Created by Artem Novichkov on 04.08.2025.
//

import FoundationModels

extension Transcript {

    static let mock: Transcript = .init(entries: [
        Transcript.Entry.instructions(.init(segments: [.text(.init(content: "1"))], toolDefinitions: [])),
        Transcript.Entry.prompt(.init(segments: [.text(.init(content: "2"))])),
        Transcript.Entry.response(.init(assetIDs: [], segments: [.text(.init(content: "3"))]))
    ])
}
