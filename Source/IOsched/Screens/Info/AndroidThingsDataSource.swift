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

import Domain
import Platform

class AndroidThingsDataSource {

  private let userState: WritableUserState

  private lazy var scavengerHuntStartDate: Date = {
    // Ugly, but prevents us from having to alloc another date formatter.
    // This will return 7am on May 8th, when Google I/O starts.
    // TODO: Refactor this date stuff to not be tied to AgendaItem
    return AgendaItem.allAgendaItems[1][0].startDate
  }()

  public init(userState: WritableUserState = DefaultServiceLocator.sharedInstance.userState) {
    self.userState = userState
  }

  var shouldDisplayAndroidThingsCell: Bool {
    let scavengerHuntHasBegun = scavengerHuntStartDate.timeIntervalSince(Date()) <= 0
    return userState.isUserRegistered && scavengerHuntHasBegun
  }

}
