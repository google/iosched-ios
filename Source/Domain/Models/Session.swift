//
//  Copyright (c) 2017 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public struct Session: TimedDetailedEvent {
  public let id: String
  public let url: URL
  public let title: String
  public let detail: String //description
  public let startTimestamp: Date
  public let endTimestamp: Date
  public let isLivestream: Bool
  public let youtubeUrl: URL?
  public let tagNames: [String]
  public let mainTagId: String
  public let color: String?
  public let speakerIds: [String]
  public let roomId: String
  public let roomName: String
  public let speakers: [Speaker]
}

public extension String {
  enum SessionConstants {
    static let keynoteId = "__keynote"
  }

  public var isKeynoteId: Bool {
    return self.hasPrefix(SessionConstants.keynoteId)
  }
}

public extension Session {
  var isKeynote: Bool {
    return id.isKeynoteId
  }
}

public enum SessionType {
  case session
  case keynote
  case codelab
  case sandboxtalk
  case misc
}

public extension Session {
  var type: SessionType {
    // TODO(morganchen): add keynote support
    if tagNames.contains("keynote") {
      return .keynote
    }
    else if tagNames.contains(EventTag.sessions.name) {
      return .session
    }
    else if tagNames.contains(EventTag.codelabs.name) {
      return .codelab
    }
    else if tagNames.contains(EventTag.sandbox.name) {
      return .sandboxtalk
    }
    else {
      return .misc
    }
  }
}

public extension Session {
  var notificationTime: Date {
    return startTimestamp.addingTimeInterval(-15 * 60)
  }
}

extension Session: Equatable { }

public func == (lhs: Session, rhs: Session) -> Bool {
  return lhs.id == rhs.id
    && lhs.startTimestamp == rhs.startTimestamp
    && lhs.endTimestamp == rhs.endTimestamp
}
