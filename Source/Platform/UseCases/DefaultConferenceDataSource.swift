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
import Domain

class DefaultConferenceDataSource {
  fileprivate var sessionsRepository: SessionsRepository
  fileprivate var roomsRepository: RoomsRepository
  fileprivate var tagsRepository: TagsRepository
  fileprivate var speakersRepository: SpeakersRepository
  fileprivate var mapRepository: MapRepository

  init(sessionsRepository: SessionsRepository, roomsRepository: RoomsRepository, tagsRepository: TagsRepository, speakersRepository: SpeakersRepository, mapRepository: MapRepository) {
    self.sessionsRepository = sessionsRepository
    self.roomsRepository = roomsRepository
    self.tagsRepository = tagsRepository
    self.speakersRepository = speakersRepository
    self.mapRepository = mapRepository
  }
}

extension DefaultConferenceDataSource: ConferenceDataSource {

  var allEvents: [TimedDetailedEvent] {
    return (allSessions as [TimedDetailedEvent])
  }

  var allSessions: [Session] {
    return sessionsRepository.sessions
  }

  func randomSessionId() -> String? {
    return sessionsRepository.randomSessionId()
  }

  func session(by sessionId: String) -> Session? {
    return sessionsRepository.session(byId: sessionId)
  }

  var allRooms: [Room] {
    return roomsRepository.rooms
  }

  func room(by roomId: String) -> Room? {
    return roomsRepository.room(byId: roomId)
  }

  var allTopics: [EventTag] {
    return tagsRepository.allTopics
  }

  var allTypes: [EventTag] {
    return tagsRepository.allTypes
  }

  var allLevels: [EventTag] {
    return tagsRepository.allLevels
  }

  var allSpeakers: [Speaker] {
    return speakersRepository.speakers
  }

  func speaker(by speakerId: String) -> Speaker? {
    return speakersRepository.speaker(byId: speakerId)
  }

  var map: Map? {
    return mapRepository.map
  }
}
