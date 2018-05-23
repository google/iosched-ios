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
import FirebaseAuth

public extension Firestore {

  private var root: DocumentReference {
    return document("google_io_events/2019")
  }

  // MARK: - Top-level collections

  /// Returns the top-level users collection.
  var users: CollectionReference {
    return root.collection("users")
  }

  /// Returns the top-level schedule summaries collection.
  var scheduleSummaries: CollectionReference {
    return root.collection("scheduleSummary")
  }

  /// Returns all the schedule details collection.
  var scheduleDetails: CollectionReference {
    return root.collection("scheduleDetail")
  }

  /// Returns the top-level event detail collection.
  var events: CollectionReference {
    return root.collection("events")
  }

  /// Returns the top-level feed item collection.
  var feed: CollectionReference {
    return root.collection("feed")
  }

  // MARK: - Session details

  /// Returns the schedule detail document with the given ID.
  func scheduleDetail(scheduleID: String) -> DocumentReference {
    return scheduleDetails.document(scheduleID)
  }

  // MARK: - User Events

  /// Returns a collection of UserEvents for the given user.
  func userEvents(for user: UserInfo) -> CollectionReference {
    return userDocument(for: user).collection("events")
  }

  /// Returns the collection of UserEvents that have nonnull reservation statuses.
  func reservations(for user: UserInfo) -> Query {
    return userEvents(for: user).whereField("reservationStatus", isGreaterThanOrEqualTo: "")
  }

  /// Returns a document reference pointing to user data for a particular event.
  func userEvent(for user: UserInfo, withSessionID sessionID: String) -> DocumentReference {
    return userEvents(for: user).document(sessionID)
  }

  // MARK: - User Document

  /// Returns the user document for the provided user.
  func userDocument(for user: UserInfo) -> DocumentReference {
    return users.document(user.uid)
  }

  /// Sets the last visited timestamp for the provided user.
  func setLastVisitedDate(for user: UserInfo) {
    let document = userDocument(for: user)
    document.setData(["lastUsage": FieldValue.serverTimestamp()], merge: true)
  }

  /// Returns the reservation queue document for the provided user.
  func reservationQueue(for user: UserInfo) -> DocumentReference {
    return root.collection("queue").document(user.uid)
  }

  // MARK: - FCM Tokens

  // There's no read logic here since the client never reads its own FCM tokens.

  /// Associates the device's FCM token with the user on the server. Should be invoked when
  /// a new user session begins.
  func setToken(_ fcmToken: String, for user: UserInfo) {
    let tokenDocument = root.collection("users")
        .document(user.uid)
        .collection("fcmTokens")
        .document(fcmToken)

    let millisecondsSinceEpoch = Int(Date().timeIntervalSince1970 * 1000)
    tokenDocument.setData(["lastVisit": millisecondsSinceEpoch]) { error in
      if let error = error {
        print("Error writing FCM token to \(self): \(error)")
      }
    }
  }

  /// Removes the user-to-device association on the server. This should be invoked on signout.
  func removeToken(_ fcmToken: String, for user: UserInfo) {
    let tokenDocument = root.collection("users")
        .document(user.uid)
        .collection("fcmTokens")
        .document(fcmToken)

    tokenDocument.delete { error in
      if let error = error {
        print("Error deleting FCM token in \(self): \(error)")
      }
    }
  }

}
