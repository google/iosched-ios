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

/// The fundamental data type of IOSched. Event and Session are used interchangeably
/// in the app's variables and comments to refer to sessions represented by this struct.
public struct Session {

  /// A unique per-session ID.
  public let id: String

  /// The session's web url.
  public let url: URL

  /// The title of the session, displayed in the Sessions screen.
  public let title: String

  /// A short paragraph describing the session content, displayed in the Session detail screen.
  public let detail: String

  /// The time the session begins.
  public let startTimestamp: Date

  /// The time the session ends.
  public let endTimestamp: Date

  /// The livestream or recording URL of the session.
  public let youtubeURL: URL?

  /// The tag metadata associated with the event.
  public let tags: [EventTag]

  /// Used for cosmetic purposes. There's no notion of "main topic" on the backend.
  public let mainTopic: EventTag?

  /// The unique identifier of the room hosting the session.
  public let roomId: String

  /// The name of the room hosting the session, which is also unique.
  public let roomName: String

  /// The speakers leading the session.
  public let speakers: [Speaker]

  /// Initializes a session with the provided values.
  public init(id: String,
              url: URL,
              title: String,
              detail: String,
              startTimestamp: Date,
              endTimestamp: Date,
              youtubeURL: URL?,
              tags: [EventTag],
              mainTopic: EventTag?,
              roomId: String,
              roomName: String,
              speakers: [Speaker]) {
    self.id = id
    self.url = url
    self.title = title
    self.detail = detail
    self.startTimestamp = startTimestamp
    self.endTimestamp = endTimestamp
    self.youtubeURL = youtubeURL
    self.tags = tags
    self.mainTopic = mainTopic
    self.roomId = roomId
    self.roomName = roomName
    self.speakers = speakers
  }
}

public extension String {
  enum SessionConstants {
    static let keynoteId = "__keynote"
  }

  var isKeynoteId: Bool {
    return self.hasPrefix(SessionConstants.keynoteId)
  }
}

public extension Session {
  var isKeynote: Bool {
    return id.isKeynoteId
  }
}

public enum SessionType {
  case afterHours
  case gameReviews
  case keynotes
  case meetups
  case appReviews
  case codelabs
  case officeHours
  case sessions
  case misc
}

public extension Session {
  var type: SessionType {
    if tags.contains(EventTag.afterHours) {
      return .afterHours
    }
    if tags.contains(EventTag.gameReviews) {
      return .gameReviews
    }
    if tags.contains(EventTag.keynotes) {
      return .keynotes
    }
    if tags.contains(EventTag.meetups) {
      return .meetups
    }
    if tags.contains(EventTag.appReviews) {
      return .appReviews
    }
    if tags.contains(EventTag.codelabs) {
      return .codelabs
    }
    if tags.contains(EventTag.officeHours) {
      return .officeHours
    }
    if tags.contains(EventTag.sessions) {
      return .sessions
    }
    return .misc
  }

  var isReservable: Bool {
    let type = self.type
    switch type {
    case .gameReviews, .appReviews, .officeHours, .sessions:
      return true
    case _:
      return false
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
