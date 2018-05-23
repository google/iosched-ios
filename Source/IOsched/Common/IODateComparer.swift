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

public class IODateComparer {

  public enum CompareResult {
    case before
    case during
    case after
  }

  public static let ioStartDate: Date = {
    let dateComponents = DateComponents(calendar: Calendar.current,
                                        timeZone: TimeUtils.pacificTimeZone,
                                        era: nil,
                                        year: 2019,
                                        month: 5,
                                        day: 7,
                                        hour: 10,
                                        minute: 0,
                                        second: 0,
                                        nanosecond: 0,
                                        weekday: nil,
                                        weekdayOrdinal: nil,
                                        quarter: nil,
                                        weekOfMonth: nil,
                                        weekOfYear: nil,
                                        yearForWeekOfYear: nil)
    return dateComponents.date!
  }()

  public static let ioEndDate: Date = {
    let dateComponents = DateComponents(calendar: Calendar.current,
                                        timeZone: TimeUtils.pacificTimeZone,
                                        era: nil,
                                        year: 2019,
                                        month: 5,
                                        day: 9,
                                        hour: 23,
                                        minute: 0,
                                        second: 0,
                                        nanosecond: 0,
                                        weekday: nil,
                                        weekdayOrdinal: nil,
                                        quarter: nil,
                                        weekOfMonth: nil,
                                        weekOfYear: nil,
                                        yearForWeekOfYear: nil)
    return dateComponents.date!
  }()

  public static func dateRelativeToIO(_ date: Date) -> IODateComparer.CompareResult {
    if date < IODateComparer.ioStartDate {
      return .before
    }
    if date > IODateComparer.ioEndDate {
      return .after
    }
    return .during
  }

  public static func currentDateRelativeToIO() -> IODateComparer.CompareResult {
    return dateRelativeToIO(Date())
  }

}
