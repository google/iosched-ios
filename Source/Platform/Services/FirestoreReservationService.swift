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

/// A type that observes reservation status changes for a single session. This type can also
/// create and modify reservations.
/// - SeeAlso: FirestoreReservationService
public protocol FirebaseReservationServiceInterface {

  /// Whether or not the reservation service should send the initial state of the reservation,
  /// provided on first fetch. Defaults to false.
  var sendsInitialReservationResultState: Bool { get set }

  /// Attaches a listener that is retained by the reservation service. This closure will be invoked
  /// when a session becomes full or becomes partially vacant after having previously been filled.
  /// If there is no user signed in, this method does nothing.
  func onSeatAvailabilityUpdate(_ result: @escaping (Bool) -> Void) -> FirebaseReservationServiceInterface

  /// Attaches a listener that is retained by the reservation service. This closure will be invoked
  /// when a session's reservation status changes. If there is no user signed in, this method
  /// does nothing.
  func onReservationStatusUpdate(_ result: @escaping (_ reservationStatus: ReservationStatus) -> Void) -> FirebaseReservationServiceInterface

  /// Attaches a listener that is retained by the reservation service. This closure will be invoked
  /// whenever the result of a reservation request changes. If there is no user signed in, this
  /// method does nothing.
  func onReservationResultUpdate(_ result: @escaping (_ reservationResult: ReservationResult) -> Void) -> FirebaseReservationServiceInterface

  /// Attempts to reserve a seat at the session referenced by `sessionID`.
  func attemptReservation()

  /// Tries to cancel an active reservation at the session referenced by `sessionID`.
  func attemptCancellation()

  /// Tries to swap the receiver's reservation with an existing reservation at the same time slot.
  func attemptSwap(withConflictingSessionID: String)

  /// Removes all update listeners.
  func removeUpdateListeners()

  /// Returns a boolean indicating whether or not there are seats available. This method will always
  /// return false before onSeatsAvailabilityUpdate is called.
  var seatsAvailable: Bool { get }

  /// Returns the reservation status of the current session. This method will always return .none
  /// before onReservationStatusUpdate is called.
  var reservationStatus: ReservationStatus { get }
}

public final class FirestoreReservationService: FirebaseReservationServiceInterface {

  public let sessionID: String
  public let currentUserProvider: CurrentUserProvider

  public var sendsInitialReservationResultState: Bool = false

  /// Used to track whether or not we've sent the initial state.
  private lazy var initialStateHasPassed: Bool = sendsInitialReservationResultState

  public init(sessionID: String, currentUserProvider: CurrentUserProvider = Auth.auth()) {
    self.sessionID = sessionID
    self.currentUserProvider = currentUserProvider
  }

  deinit {
    seatsListener?.remove()
    reservationStatusListener?.remove()
    reservationResultsListener?.remove()
  }

  // MARK: - Seats availability

  public var seatsAvailable: Bool = false

  private var seatsListener: ListenerRegistration? {
    willSet {
      seatsListener?.remove()
    }
  }

  public func onSeatAvailabilityUpdate(_ result: @escaping (Bool) -> Void) -> FirebaseReservationServiceInterface {

    let seatsAvailableRef = Firestore.firestore().scheduleDetail(scheduleID: self.sessionID)

    let sessionID = self.sessionID
    seatsListener = seatsAvailableRef.addSnapshotListener { [weak self] (snapshot, error) in
      guard let document = snapshot else {
        let errorDescription = error.map({ String(describing: $0) }) ?? "null"
        print("Error retrieving session \(sessionID) information: \(errorDescription)")
        result(false)
        return
      }
      let sessionFull = document.data()?["sessionFull"] as? Bool ?? false

      let seatsAvailable = !sessionFull
      self?.seatsAvailable = seatsAvailable
      result(seatsAvailable)
    }

    return self
  }

  // MARK: - Reservation result handling

  public func removeUpdateListeners() {
    reservationResultsListener = nil
    reservationStatusListener = nil
    seatsListener = nil
  }

  public var reservationStatus: ReservationStatus = .none

  private var reservationStatusListener: ListenerRegistration? {
    willSet {
      reservationStatusListener?.remove()
    }
  }

  public func onReservationStatusUpdate(_ result: @escaping (ReservationStatus) -> Void) -> FirebaseReservationServiceInterface {

    guard let user = currentUserProvider.currentUserInfo else {
      print("Error: user not signed in.")
      return self
    }

    // This fetches all user events, since Firestore doesn't support filtered queries with
    // multiple possible filter values yet. This doesn't waste data, though, since the only
    // other user events, bookmarks, are used elsewhere.
    let reservationStatusRef = Firestore.firestore()
        .userEvent(for: user, withSessionID: self.sessionID)

    let sessionID = self.sessionID
    reservationStatusListener = reservationStatusRef.addSnapshotListener { [weak self] (snapshot, error) in
      guard let self = self else { return }
      guard let document = snapshot else {
        let errorDescription = error.map({ String(describing: $0) }) ?? "null"
        print("Error retrieving session \(sessionID) information: \(errorDescription)")
        return
      }

      guard let data = document.data(), !data.isEmpty else {
        // Empty data means the session isn't reserved.
        self.reservationStatus = .none
        result(.none)
        return
      }

      guard let status = document["reservationStatus"] as? String else {
        self.reservationStatus = .none
        result(.none)
        return
      }

      if let reservationStatus = ReservationStatus(rawValue: status) {
        self.reservationStatus = reservationStatus
        result(reservationStatus)
      } else {
        print("Unexpected value when fetching reservation status: \(status)")
        self.reservationStatus = .none
        result(.none)
      }
    }
    return self
  }

  // MARK: - Reservation result

  private var reservationResultsListener: ListenerRegistration? {
    willSet {
      reservationResultsListener?.remove()
      initialStateHasPassed = false
    }
  }

  public func onReservationResultUpdate(_ result: @escaping (ReservationResult) -> Void) -> FirebaseReservationServiceInterface {

    guard let user = currentUserProvider.currentUserInfo else {
      print("Error: user not signed in.")
      return self
    }

    let reservationResultsRef = Firestore.firestore()
        .userEvent(for: user, withSessionID: self.sessionID)

    let sessionID = self.sessionID
    reservationResultsListener = reservationResultsRef.addSnapshotListener { [weak self] (snapshot, error) in
      guard let self = self else { return }
      guard let document = snapshot else {
        let errorDescription = error.map({ String(describing: $0) }) ?? "null"
        print("Error retrieving session \(sessionID) information: \(errorDescription)")
        return
      }

      guard self.initialStateHasPassed else {
        self.initialStateHasPassed = true
        return
      }

      guard let data = document.data(), !data.isEmpty else {
        // If there's no data here, the user does not have a reservation.
        return
      }

      guard let partialResult = (document["reservationResult"] as? [String: Any]) else {
        return
      }
      guard let reservationResult = (partialResult["requestResult"] as? String)
          .flatMap(ReservationResult.init(rawValue:)) else {
        print("Unexpected type/value when fetching reservation status: \(document.data() ?? [:])")
        return
      }

      result(reservationResult)
    }

    return self
  }

  public func attemptReservation() {
    performRegistrationAction(action: .reserve)
  }

  public func attemptCancellation() {
    performRegistrationAction(action: .cancel)
  }

  public func attemptSwap(withConflictingSessionID conflictingSessionID: String) {
    performRegistrationAction(action: .swap, conflictingSessionID: conflictingSessionID)
  }

  /// Reservation actions overwrite previously-existing reservations that may be unprocessed.
  /// conflictingSessionID is ignored if the actionType is not .swap.
  private func performRegistrationAction(action actionType: ReservationQueueActionType,
                                         conflictingSessionID: String? = nil) {
    guard let user = currentUserProvider.currentUserInfo else {
      return
    }

    let queueDocument = Firestore.firestore().reservationQueue(for: user)

    let requestID = UUID().uuidString

    let timestamp = Int(Date().timeIntervalSince1970 * 1000)

    var request: [String: Any] = [
      "sessionId": sessionID,
      "requestId": requestID,
      "timestamp": timestamp
    ]

    switch actionType {
    case .reserve:
      request["action"] = "RESERVE"
    case .swap:
      guard let conflictingSessionID = conflictingSessionID else { return }
      request["action"] = "SWAP"
      request["cancelSessionId"] = conflictingSessionID
      request["reserveSessionId"] = sessionID
      request.removeValue(forKey: "sessionId")
    case .cancel:
      request["action"] = "CANCEL"
    }

    queueDocument.setData(request)
  }

}
