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

import FirebaseFirestore

/// A class responsible for syncing sessions data with Firestore.
class MRUScheduleDatasource: AutoUpdatingConferenceData {

  private var scheduleDetailsQuerySnapshot: QuerySnapshot?
  private var listener: ListenerRegistration?

  var conference: [Session] {
    var sessions: [Session] = []
    guard let snapshot = scheduleDetailsQuerySnapshot else { return [] }
    for scheduleDetail in snapshot.documents {
      if let session = Session(scheduleDetail: scheduleDetail) {
        sessions.append(session)
      }
    }
    return sessions
  }

  /// Populates the receiver with data from Firestore and subscribes to automatic data updates.
  /// On every new update, the updateHandler will be invoked with a bool flag indicating
  /// whether or not the update contained new data.
  func subscribeToUpdates(_ updateHandler: @escaping (Bool) -> Void) {
    let scheduleDetails = Firestore.firestore().scheduleDetails
    listener?.remove()
    listener = scheduleDetails.addSnapshotListener { [weak self] (querySnapshot, error) in
      if let error = error {
        print("Error getting scheduleDetails \(error))")
      }
      self?.scheduleDetailsQuerySnapshot = querySnapshot
      let hasChanges = querySnapshot.map { $0.documentChanges.count > 0 } ?? false
      updateHandler(hasChanges)
    }
  }

  deinit {
    listener?.remove()
  }

}
