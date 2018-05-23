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

public enum ReservationStatus: String {
  case reserved = "RESERVED"
  case waitlisted = "WAITLISTED"
  case none = "NONE"
}

public enum ReservationResult: String {
  case reserved = "RESERVE_SUCCEEDED"
  case waitlisted = "RESERVE_WAITLISTED"
  case cutoff = "RESERVE_DENIED_CUTOFF"
  case clash = "RESERVE_DENIED_CLASH"
  case unknown = "RESERVE_DENIED_UNKNOWN"

  case swapped = "SWAP_SUCCEEDED"
  case swapWaitlisted = "SWAP_WAITLISTED"
  case swapCutoff = "SWAP_DENIED_CUTOFF"
  case swapClash = "SWAP_DENIED_CLASH"
  case swapUnknown = "SWAP_DENIED_UNKNOWN"

  case cancelled = "CANCEL_SUCCEEDED"
  case cancelCutoff = "CANCEL_DENIED_CUTOFF"
  case cancelUnknown = "CANCEL_DENIED_UNKNOWN"
}

// Constants for NotificationCenter updates
public enum ReservationUpdates {
  public static let sessionId = "sessionId"
  public static let isReserved = "isReserved"
}

public extension Notification.Name {
  public static let reservationUpdate = Notification.Name("reservationUpdate")
}

public typealias ReservationUpdate = (_ sessionId: String, _ reserved: Bool) -> Void

public protocol ReadonlyReservationStore {
  func reservationStatus(sessionId: String) -> ReservedSessionStatus
  func updateReservationStatus(sessionId: String, status: ReservationStatus)
  func purgeLocalReservations()
  func sync()
  func sync(_ completion: (() -> Void)?)
}
