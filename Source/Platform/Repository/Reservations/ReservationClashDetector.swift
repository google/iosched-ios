//
//  Copyright (c) 2019 Google Inc.
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

public class ReservationClashDetector {

  private let sessionsDataSource: LazyReadonlySessionsDataSource
  private let reservationDataSource: RemoteReservationDataSource

  public init(sessions: LazyReadonlySessionsDataSource, reservations: RemoteReservationDataSource) {
    sessionsDataSource = sessions
    reservationDataSource = reservations
  }

  public func clashes(forID sessionID: String) -> [Session] {
    guard let session = sessionsDataSource[sessionID] else { return [] }
    return clashes(for: session)
  }

  public func clashes(for reservedSession: Session) -> [Session] {
    var clashes: [Session] = []
    for existingReservation in reservationDataSource.reservedSessions
      where existingReservation.status != .none {
        guard let session = sessionsDataSource[existingReservation.id] else { continue }

        let isOverlapping = overlap(startDate1: session.startTimestamp,
                                    endDate1: session.endTimestamp,
                                    startDate2: reservedSession.startTimestamp,
                                    endDate2: reservedSession.endTimestamp)
        if isOverlapping {
          clashes.append(session)
        }
    }
    return clashes
  }

  private func overlap(startDate1: Date, endDate1: Date, startDate2: Date, endDate2: Date) -> Bool {
    if startDate2 >= startDate1 && startDate2 < endDate1 {
      return true
    }
    if endDate2 > startDate1 && endDate2 <= endDate1 {
      return true
    }
    return false
  }

}
