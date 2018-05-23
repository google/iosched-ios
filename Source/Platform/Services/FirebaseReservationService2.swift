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

public protocol FirebaseReservationServiceInterface {
  func onSeatAvailabilityUpdate(_ result: @escaping (Bool) -> Void) -> FirebaseReservationServiceInterface
  func onReservationProcessUpdate(_ result: @escaping (_ reservationStatus: ReservationStatus) -> Void) -> FirebaseReservationServiceInterface
  func onReservationResultUpdate(_ result: @escaping (_ reservationResult: ReservationResult) -> Void) -> FirebaseReservationServiceInterface
  func attemptReservation()
  func attemptCancellation()

  var seatsAvailable: Bool { get }
  var reservationStatus: ReservationStatus { get }
}

public final class FirebaseReservationService2: FirebaseReservationServiceInterface {

  private enum FirebaseConstants {
    static let sessions = "sessions"
    static let seats = "seats"
    static let seatsAvailable = "seats_available"
    static let reservations = "reservations"
    static let status = "status"
    static let results = "results"
    static let queue = "queue"
  }

  private let sessionID: String

  public init(sessionID: String) {
    self.sessionID = sessionID
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

    // This sessionID is copied to a local variable outside the closure so the closure
    // doesn't have to reference self.
    let sessionID = self.sessionID
    seatsListener = seatsAvailableRef.addSnapshotListener { [weak self] (snapshot, error) in
      guard let document = snapshot else {
        let errorDescription = error.map({ String(describing: $0) }) ?? "null"
        print("Error retrieving session \(sessionID) information: \(errorDescription)")
        result(false)
        return
      }

      let sessionFull = document.data()?["sessionFull"] as? Bool ?? true

      let seatsAvailable = !sessionFull
      self?.seatsAvailable = seatsAvailable
      result(seatsAvailable)
    }

    return self
  }

  // MARK: - Reservation result handling

  public var reservationStatus: ReservationStatus = .none

  private var reservationStatusListener: ListenerRegistration? {
    willSet {
      reservationStatusListener?.remove()
    }
  }

  public func onReservationProcessUpdate(_ result: @escaping (ReservationStatus) -> Void) -> FirebaseReservationServiceInterface {

    guard let user = Auth.auth().currentUser else {
      print("Error: user not signed in.")
      return self
    }

    let reservationStatusRef = Firestore.firestore()
        .userEvent(for: user, withSessionID: self.sessionID)

    let sessionID = self.sessionID
    reservationStatusListener = reservationStatusRef.addSnapshotListener { [weak self] (snapshot, error) in
      guard let document = snapshot else {
        let errorDescription = error.map({ String(describing: $0) }) ?? "null"
        print("Error retrieving session \(sessionID) information: \(errorDescription)")
        return
      }

      guard let data = document.data(), !data.isEmpty else {
        // Empty data means the session isn't reserved.
        self?.reservationStatus = .none
        result(.none)
        return
      }

      guard let status = document["reservationStatus"] as? String else {
        print("Unexpected type when fetching reservation status: \(data)")
        return
      }

      if let reservationStatus = ReservationStatus(rawValue: status) {
        self?.reservationStatus = reservationStatus
        result(reservationStatus)
      } else {
        print("Unexpected value when fetching reservation status: \(status)")
      }

    }

    return self
  }

  // MARK: - Reservation result

  private var reservationResultsListener: ListenerRegistration? {
    willSet {
      reservationResultsListener?.remove()
    }
  }

  public func onReservationResultUpdate(_ result: @escaping (ReservationResult) -> Void) -> FirebaseReservationServiceInterface {

    guard let user = Auth.auth().currentUser else {
      print("Error: user not signed in.")
      return self
    }

    let reservationResultsRef = Firestore.firestore()
        .userEvent(for: user, withSessionID: self.sessionID)

    let sessionID = self.sessionID
    reservationResultsListener = reservationResultsRef.addSnapshotListener { (snapshot, error) in
      guard let document = snapshot else {
        let errorDescription = error.map({ String(describing: $0) }) ?? "null"
        print("Error retrieving session \(sessionID) information: \(errorDescription)")
        return
      }

      guard let data = document.data(), !data.isEmpty else {
        // If there's no data here, the user does not have a reservation.
        return
      }

      guard let reservationResult = (document["reservationResult"] as? [String: Any])
          .flatMap({ $0["requestResult"] as? String })
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

  /// Reservation actions overwrite previously-existing reservations that may be unprocessed.
  private func performRegistrationAction(action actionType: ReservationQueueActionType) {
    guard let user = Auth.auth().currentUser else {
      return
    }

    let queueDocument = Firestore.firestore().reservationQueue(for: user)

    let requestID = NSUUID().uuidString

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
      // TODO(morganchen): implement swap
      return
    case .cancel:
      request["action"] = "CANCEL"
    }

    queueDocument.setData(request)
  }

}
