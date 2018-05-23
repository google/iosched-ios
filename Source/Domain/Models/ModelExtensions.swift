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

public protocol TitledEvent {
  var title: String { get }
}

public protocol DetailedEvent: TitledEvent {
  var detail: String { get }
}

public protocol TimedEvent {
  var startTimestamp: Date { get }
  var endTimestamp: Date { get }
}

public protocol TimedDetailedEvent: DetailedEvent, TimedEvent { }

public extension Conference {
  var events: [TimedDetailedEvent] {
    let nonEmptyBlocks = blocks.filter { !$0.isFree }
    return (self.sessions as [TimedDetailedEvent]) + (nonEmptyBlocks as [TimedDetailedEvent])
  }
}
