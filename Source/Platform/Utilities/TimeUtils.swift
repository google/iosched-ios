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

public struct TimeUtils {

  /// Pacific time zone.
  public static let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles")!

  private struct Constants {
    /// Formatter for reading time stamps from the json. Not for the modified date.
    static var TimeStampDateFormatter: DateFormatter = {
      let dateFormatter = DateFormatter()

      return dateFormatter
    }()

    static let DateFormats = [
      "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
      "yyyy-MM-dd'T'HH:mm:ssZ",
      "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
      "yyyy-MM-dd'T'HH:mm:ss Z",
      "yyyy-MM-dd'T'HH:mm:ssZ",
      "yyyy-MM-dd HH:mm:ss Z"
      ]
  }

  static func dateFromString(_ timeStamp: String) -> Date? {
    var date: Date? = nil

    for dateFormat in Constants.DateFormats {
      Constants.TimeStampDateFormatter.dateFormat = dateFormat
      date = Constants.TimeStampDateFormatter.date(from: timeStamp)

      if date != nil {
        break
      }
    }

    return date
  }

  static func timeStampFromDate(_ date: Date?) -> String {
    guard let date = date else {
      return ""
    }

    let dateFormat = Constants.DateFormats.first!
    Constants.TimeStampDateFormatter.dateFormat = dateFormat
    Constants.TimeStampDateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)

    return Constants.TimeStampDateFormatter.string(from: date)
  }

}
