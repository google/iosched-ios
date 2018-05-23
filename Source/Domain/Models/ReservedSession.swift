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

//public enum ReservedSessionStatus: String {
//  case reserved = "RESERVED"
//  case waitlisted = "WAITLISTED"
//  case deleted = "DELETED"
//}

public typealias ReservedSessionStatus = ReservationStatus

public struct ReservedSession {
  public let id: String
  public let status: ReservedSessionStatus
  public let timestamp: Int

  public init(id: String, status: ReservedSessionStatus, timestamp: String) {
    self.id = id
    self.status = status
    self.timestamp = Int(timestamp) ?? 0
  }

  public init(id: String, status: ReservedSessionStatus, timestamp: Int) {
    self.id = id
    self.status = status
    self.timestamp = timestamp
  }

}

extension ReservedSession: Equatable { }

public func == (lhs: ReservedSession, rhs: ReservedSession) -> Bool {
  return lhs.id == rhs.id
}
