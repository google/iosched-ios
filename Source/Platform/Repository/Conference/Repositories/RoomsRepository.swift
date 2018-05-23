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

protocol RoomsRepository: UpdatableRepository {
  var rooms: [Room] { get }

  subscript(id: String) -> Room? { get }
  func room(byId id: String) -> Room?
}

class DefaultRoomsRepository: RoomsRepository {
  fileprivate var datasource: ConferenceData

  fileprivate var roomsMap = [String: Room]()

  init(datasource: ConferenceData) {
    self.datasource = datasource
    update()
  }

  func update() {
    fetchRooms()
  }
}

// MARK: - Accessing elements

extension DefaultRoomsRepository {
  var rooms: [Room] {
    return Array(roomsMap.values)
  }

  subscript(id: String) -> Room? {
    return roomsMap[id]
  }

  func room(byId id: String) -> Room? {
    return roomsMap[id]
  }
}

// MARK: - Updating elements from the data source

extension DefaultRoomsRepository {
  func fetchRooms() {
    guard let conference = datasource.conference else {
      print("Repository didn't get any conference data. Not updating repository state.")
      return
    }

    conference.rooms.forEach { room in
      roomsMap[room.id] = room
    }
  }
}
