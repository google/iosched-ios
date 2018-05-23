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
import FirebaseFirestore

class MRUScheduleDatasource: ConferenceData, UpdatableDatasource {

  private var scheduleDetailsQuerySnapshot: QuerySnapshot?
  private var listener: ListenerRegistration?

  var conference: Conference? {
    // TODO(thkien): refactor data transformation logic into Conference+Firestore.swift instead.
    var sessions: [Session] = []
    guard let snapshot = scheduleDetailsQuerySnapshot else { return nil }
    for scheduleDetail in snapshot.documents {
      if let session = Session(scheduleDetail: scheduleDetail) {
        sessions.append(session)
      }
    }
    return Conference(map: Map(mapMetadata: nil),
                      rooms: [],
                      sessions: sessions,
                      blocks: [],
                      speakers: [],
                      tags: [])
  }

  func update(_ completion: @escaping (Bool) -> Void) {
    let scheduleDetails = Firestore.firestore().scheduleDetails
    listener?.remove()
    listener = scheduleDetails.addSnapshotListener { [weak self] (querySnapshot, error) in
      if let error = error {
        print("Error getting scheduleDetails \(error))")
      }
      self?.scheduleDetailsQuerySnapshot = querySnapshot
      let hasChanges = querySnapshot.map { $0.documentChanges.count > 0 } ?? false
      completion(hasChanges)
    }
  }

  deinit {
    listener?.remove()
  }

}
