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

// Constants for NotificationCenter updates
public extension Notification.Name {
  public static let conferenceUpdate = Notification.Name("conferenceUpdate")
}

public protocol ConferenceDataSource {
  var allEvents: [TimedDetailedEvent] { get }

  var allSessions: [Session] { get }
  func session(by sessionId: String) -> Session?
  func randomSessionId() -> String?

  var allRooms: [Room] { get }
  func room(by roomId: String) -> Room?

  var allTopics: [EventTag] { get }
  var allTypes: [EventTag] { get }
  var allLevels: [EventTag] { get }

  var allSpeakers: [Speaker] { get }
  func speaker(by speakerId: String) -> Speaker?

  var map: Map? { get }
}
