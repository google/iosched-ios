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
import UIKit
import Domain

class MyIOViewModel: DefaultScheduleViewModel {

  /// Returns all slots for the given day that contain at least one boookmarked session
  override func slots(forDayWithIndex index: Int) -> [ConferenceTimeSlotViewModel]? {
    if conferenceDays.count == 0 {
      return []
    }
    return conferenceDays[index].slots.filter { scheduleTimeSlotViewModel -> Bool in
      return scheduleTimeSlotViewModel
        .events
        .filter { $0.isBookmarked || $0.reservationStatus == .reserved }
        .count > 0
    }
  }

  /// Returns all events for a given day and time slot
  override func events(forDayWithIndex dayIndex: Int, andSlotIndex slotIndex: Int) -> [ConferenceEventViewModel]? {
    let events = super.events(forDayWithIndex: dayIndex, andSlotIndex: slotIndex)
    return events?.filter { (event) -> Bool in
      return bookmarkStore.isBookmarked(sessionId: event.id) ||
          reservationStore.reservationStatus(sessionId: event.id) == .reserved
    }
  }

  func myIOAccountSelected() {
    navigator.navigateToAccount()
  }

}
