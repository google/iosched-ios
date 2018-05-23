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

  // MARK: - Top-level collections

  /// Returns the top-level users collection.
  public var users: CollectionReference {
    return self.collection("users")
  }

  /// Returns the top-level schedule summaries collection.
  public var scheduleSummaries: CollectionReference {
    return self.collection("scheduleSummary")
  }

  /// Returns all the schedule details collection.
  public var scheduleDetails: CollectionReference {
    return self.collection("scheduleDetail")
  }

  /// Returns the top-level event detail collection.
  public var events: CollectionReference {
    return self.collection("events")
  }

  // MARK: - Session details

  /// Returns the schedule detail document with the given ID.
  public func scheduleDetail(scheduleID: String) -> DocumentReference {
    return self.scheduleDetails.document(scheduleID)
  }

  // MARK: - User Events

  /// Returns a collection of UserEvents for the given user.
  public func userEvents(for user: UserInfo) -> CollectionReference {
    return self.userDocument(for: user).collection("events")
  }

  /// Returns a document reference pointing to user data for a particular event.
  public func userEvent(for user: UserInfo, withSessionID sessionID: String) -> DocumentReference {
    return self.userEvents(for: user).document(sessionID)
  }

  // MARK: - User Document

  /// Returns the user document for the provided user.
  public func userDocument(for user: UserInfo) -> DocumentReference {
    return self.users.document(user.uid)
  }

  /// Sets the last visited timestamp for the provided user.
  public func setLastVisited(_ date: Date, for user: UserInfo) {
    let document = userDocument(for: user)
    document.setData(["lastUsage": FieldValue.serverTimestamp()], options: SetOptions.merge())
  }

  /// Returns the reservation queue document for the provided user.
  public func reservationQueue(for user: UserInfo) -> DocumentReference {
    return self.collection("queue").document(user.uid)
  }

  // MARK: - FCM Tokens

  // There's no read logic here since the client never reads its own FCM tokens.

  /// Associates the device's FCM token with the user on the server. Should be invoked when
  /// a new user session begins.
  public func setToken(_ fcmToken: String, for user: UserInfo) {
    let tokenDocument = self.collection("users")
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
  public func removeToken(_ fcmToken: String, for user: UserInfo) {
    let tokenDocument = self.collection("users")
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
