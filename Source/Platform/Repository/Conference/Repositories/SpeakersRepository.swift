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

protocol SpeakersRepository: UpdatableRepository {
  var speakers: [Speaker] { get }

  subscript(id: String) -> Speaker? { get }
  func speaker(byId id: String) -> Speaker?
}

class DefaultSpeakersRepository: SpeakersRepository {
  fileprivate var datasource: ConferenceData

  fileprivate var speakersMap = [String: Speaker]()

  init(datasource: ConferenceData) {
    self.datasource = datasource
    update()
  }

  func update() {
    fetchSpeakers()
  }
}

// MARK: - Accessing elements

extension DefaultSpeakersRepository {
  var speakers: [Speaker] {
    return Array(speakersMap.values)
  }

  subscript(id: String) -> Speaker? {
    return speakersMap[id]
  }

  func speaker(byId id: String) -> Speaker? {
    return speakersMap[id]
  }
}

// MARK: - Updating elements from the data source

extension DefaultSpeakersRepository {
  func fetchSpeakers() {
    guard let conference = datasource.conference else {
      print("Repository didn't get any conference data. Not updating repository state.")
      return
    }

    conference.speakers.forEach { speaker in
      speakersMap[speaker.id] = speaker
    }
  }
}
