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

protocol ReservationDataSource {

  /// Retrieve all reservations stored in this data source
  func retrieveReservations(_ callback: @escaping (_ reservations: [ReservedSession]) -> Void)

}

protocol WriteableReservationDataSource: ReservationDataSource {

  /// Reserve a session
  func addReservation(for sessionId: String)

  /// Remove reservation for a session
  func removeReservation(for sessionId: String)

  func updateReservationStatus(sessionId: String, status: ReservationStatus)

}

protocol BatchUpdatingReservationDataSource {
  func saveReservation(reservation: ReservedSession)

  /// Store all given reservations
  func saveReservations(reservations: [ReservedSession])
}

extension BatchUpdatingReservationDataSource {
  func saveReservations(reservations: [ReservedSession]) {
    for reservation in reservations {
      saveReservation(reservation: reservation)
    }
  }
}

protocol LocalReservationDataSource: WriteableReservationDataSource {

  /// Get reservation status for a session
  func reservationStatus(sessionId: String) -> ReservedSessionStatus

  /// Determine whether a given session is reserved or not
  func isReserved(sessionId: String) -> Bool

}

protocol PurgeableReservationDataSource: WriteableReservationDataSource {

  /// Clear all reservation, if supported by the datasource
  func purgeReservations()

}

protocol LocalPurgeableReservationDataSource: LocalReservationDataSource, PurgeableReservationDataSource, BatchUpdatingReservationDataSource {}
