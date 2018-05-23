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

public struct Block: TimedDetailedEvent {
  public let title: String
  public let detail: String
  public let startTimestamp: Date
  public let endTimestamp: Date
  public let type: BlockType
  public let kind: BlockKind?
  public let color: String?
}

public extension Block {
  public var isFree: Bool {
    return type == .free
  }

  public var isBreak: Bool {
    return type == .break
  }

  public var isMeal: Bool {
    return kind == .meal
  }

  public var isConcert: Bool {
    return kind == .concert
  }

}

extension Block: Equatable { }

public func == (lhs: Block, rhs: Block) -> Bool {
  return lhs.title == rhs.title
    && lhs.startTimestamp == rhs.startTimestamp
    && lhs.endTimestamp == rhs.endTimestamp
}

public enum BlockType: String {
  case `break` = "break"
  case free = "free"
  case unknown = ""
}

public enum BlockKind: String {
  case meal = "meal"
  case concert = "concert"
  case afterHours = "afterHours"
  case unknown = ""
}
