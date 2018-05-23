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
import FirebaseAuth

final class DefaultReservationStore: ReadonlyReservationStore {

  private let repository: ReservationRepository

  init(_ repository: ReservationRepository) {
    self.repository = repository
  }

  func updateReservationStatus(sessionId: String, status: ReservationStatus) {
    repository.updateReservationStatus(sessionId: sessionId, status: status)
    update()
  }

  func reservationStatus(sessionId: String) -> ReservedSessionStatus {
    return repository.reservationStatus(sessionId: sessionId)
  }

  func purgeLocalReservations() {
    repository.purgeLocalReservations()
    update()
  }

  func sync() {
    sync { }
  }

  func sync(_ completion: (() -> Void)?) {
    repository.reconcile {
      self.update()
      completion?()
    }
  }

  // MARK: - Publishing updates

  func update() {
    NotificationCenter.default.post(name: .reservationUpdate,
                                    object: nil,
                                    userInfo: [:])
  }

}
