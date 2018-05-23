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

protocol SessionsRepository: UpdatableRepository {
  var sessions: [Session] { get }

  subscript(id: String) -> Session? { get }
  func session(byId id: String) -> Session?
  func randomSessionId() -> String?
}

class DefaultSessionsRepository: SessionsRepository {
  fileprivate var datasource: ConferenceData

  fileprivate var sessionsMap = [String: Session]()

  init(datasource: ConferenceData) {
    self.datasource = datasource
  }

  func update() {
    fetchSessions()
  }
}

// MARK: - Accessing elements

extension DefaultSessionsRepository {
  var sessions: [Session] {
    return Array(sessionsMap.values)
  }

  subscript(id: String) -> Session? {
    return sessionsMap[id]
  }

  func session(byId id: String) -> Session? {
    return sessionsMap[id]
  }

  func randomSessionId() -> String? {
    let numberOfSessions = sessions.count
    guard sessions.count > 0 else { return nil }
    let randomIndex = Int(arc4random_uniform(UInt32(numberOfSessions - 1)))
    let randomId = sessions[randomIndex].id
    return randomId
  }

}

// MARK: - Updating elements from the data source

extension DefaultSessionsRepository {
  func fetchSessions() {
    guard let conference = datasource.conference else {
      print("Repository didn't get any conference data. Not updating repository state.")
      return
    }

    conference.sessions.forEach { session in
      sessionsMap[session.id] = session
    }
  }
}
