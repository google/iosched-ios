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
import FirebaseAuth
import GoogleSignIn

class RemoteReservationDataSource: ReservationDataSource {

  private let firestore: Firestore
  private let auth: Auth

  private var listener: ListenerRegistration?
  private var sessions: [ReservedSession] = []

  init(firestore: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
    self.firestore = firestore
    self.auth = auth
  }

  // MARK: - ReservationDataSource

  /// `onReservationUpdates` should be called before this method to start syncing values from
  /// Firestore.
  func retrieveReservations(_ callback: @escaping (_ reservations: [ReservedSession]) -> Void) {
    callback(sessions)
  }

  func onReservationUpdates(_ callback: @escaping (_ reservations: [ReservedSession]) -> Void) {
    guard let user = auth.currentUser else {
      callback([])
      return
    }

    let query = firestore.userEvents(for: user)
      .whereField("reservationStatus", isEqualTo: "RESERVED")
    listener = query.addSnapshotListener { [weak self] (querySnapshot, error) in
      guard let snapshot = querySnapshot else {
        print("Error fetching reservations: \(error!)")
        callback([])
        return
      }

      let sessions = snapshot.documents.map({ (document) -> ReservedSession? in
        let data = document.data()
        let reservationStatus = (data["reservationStatus"] as? String)
            .flatMap(ReservationStatus.init(rawValue:))
        let reservationTimestamp =
            (data["reservationResult"] as? [String: Any])?["timestamp"] as? Int
        guard let status = reservationStatus, let timestamp = reservationTimestamp else {
          print("Error: Unable to serialize reservation state: \(data)")
          return nil
        }
        return ReservedSession(id: document.documentID, status: status, timestamp: timestamp)
      })
      .filter({ $0 != nil })
      .map({ $0! })

      self?.sessions = sessions
      callback(sessions)
    }
  }

  deinit {
    listener?.remove()
  }

}
