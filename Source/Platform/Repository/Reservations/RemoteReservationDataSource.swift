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
import GoogleSignIn

/// A class responsible for fetching reservations from Firestore.
/// This class will not fetch data if there is no currently logged in user, and will
/// automatically fetch data after the `observeReservationUpdates` method is called even
/// in the event that the user signs out and re-authenticates later on. This class will
/// stop fetching data if `stopObservingUpdates` is called.
public class RemoteReservationDataSource {

  // Dependencies
  private let firestore: Firestore
  private let signIn: SignInInterface

  public private(set) var sessionsMap: [String: ReservationStatus] = [:]
  public private(set) var reservedSessions: [ReservedSession] = []

  private var listener: ListenerRegistration? {
    willSet {
      listener?.remove()
    }
  }
  private var signInHandle: AnyObject? {
    willSet {
      if let handle = signInHandle {
        signIn.removeGoogleSignInHandler(handle)
      }
    }
  }
  private var signOutHandle: AnyObject? {
    willSet {
      if let handle = signOutHandle {
        signIn.removeGoogleSignOutHandler(handle)
      }
    }
  }

  /// The closure used to handle Firestore updates. This is stored so we can
  /// automatically re-observe on auth change events.
  private var updateHandler: (([ReservedSession], Error?) -> Void)?

  /// Initializes an instance of RemoteReservationDataSource, but does not fetch data.
  public init(firestore: Firestore = Firestore.firestore(),
              signIn: SignInInterface = SignIn.sharedInstance) {
    self.firestore = firestore
    self.signIn = signIn

    observeSignInUpdates()
  }

  /// Returns the reservation status for the given session, or .none if there is none.
  public func reservationStatus(for sessionID: String) -> ReservationStatus {
    return sessionsMap[sessionID] ?? .none
  }

  private func buildSessionsMap(from sessions: [ReservedSession]) {
    reservedSessions = sessions
    sessionsMap.removeAll()
    for session in sessions {
      sessionsMap[session.id] = session.status
    }
  }

  /// Fetches data from Firestore and passes all subsequent updates to the callback handler.
  /// In certain non-Firestore events, such as sign out, the callback may be invoked with an
  /// empty array and no error parameter. Calling this method twice will remove the
  /// update handler from the first invocation.
  func observeReservationUpdates(_ callback:
      @escaping (_ reservations: [ReservedSession], Error?) -> Void) {
    updateHandler = callback
    guard let user = signIn.currentUpgradableUser else {
      callback([], nil)
      return
    }

    let query = firestore.reservations(for: user)
    listener = query.addSnapshotListener { [weak self] (querySnapshot, error) in
      guard let self = self else { return }
      defer {
        NotificationCenter.default.post(name: .reservationUpdate, object: nil)
      }

      if error.map({ $0 as NSError })?.code == FirestoreErrorCode.permissionDenied.rawValue {
        // Permission denied indicates an auth status change while the listener was active, or
        // a bug in our security rules. If this is a security rules bug, automatically retrying here
        // will be unproductive. In the case of a sign out, there may be no reservations to fetch.
        // Don't retry after this error.
        self.listener?.remove()
        // Leaving updateHandler set to a nonnull value means this class will automatically
        // restart this query listener on reauth.
        print("Permissions error fetching reservations: \(error!)")
        self.buildSessionsMap(from: [])
        callback([], error)
        return
      }
      guard let snapshot = querySnapshot else {
        print("Error fetching reservations: \(error!)")
        self.buildSessionsMap(from: [])
        callback([], error)
        return
      }

      let sessions = snapshot.documents.map({ (document) -> ReservedSession? in
        let data = document.data()
        let reservationStatus = (data["reservationStatus"] as? String)
            .flatMap(ReservationStatus.init(rawValue:))
        guard let status = reservationStatus else {
          print("Error: Unable to serialize reservation state: \(data)")
          return nil
        }
        return ReservedSession(id: document.documentID, status: status)
      })
      .filter({ $0 != nil })
      .map({ $0! })

      self.buildSessionsMap(from: sessions)
      callback(sessions, nil)
    }
  }

  /// Stops updates and releases the callback block previously passed into `observeReservationUpdates`.
  /// After this method is invoked, `observeReservationUpdates` must be invoked again to fetch new data.
  /// This method does not reset the receiver's local copy of reservations, which can result in
  /// stale data.
  func stopObservingUpdates() {
    listener = nil
    updateHandler = nil
  }

  deinit {
    listener = nil
    stopObservingSignInUpdates()
  }

  // MARK: - SignIn callbacks

  private func observeSignInUpdates() {
    signInHandle = signIn.addGoogleSignInHandler(self) { [weak self] in
      guard let self = self, let handler = self.updateHandler else { return }
      self.observeReservationUpdates(handler)
    }

    signOutHandle = signIn.addGoogleSignOutHandler(self) { [weak self] in
      guard let self = self else { return }
      self.listener = nil
      self.sessionsMap = [:]
      self.reservedSessions = []

      // Pass an empty update to the handler so this class's consumer doens't have stale data.
      self.updateHandler?([], nil)
    }
  }

  private func stopObservingSignInUpdates() {
    signInHandle = nil
    signOutHandle = nil
  }

}
