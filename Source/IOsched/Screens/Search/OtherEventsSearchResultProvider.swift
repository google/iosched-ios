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

class OtherEventsSearchResultProvider: SessionSearchResultProvider {

  private static let dateIntervalFormatter: DateIntervalFormatter = {
    let formatter = DateIntervalFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

  override var title: String {
    return NSLocalizedString("Other Events",
                             comment: "Catch-all title for any event that's not a session.")
  }

  override var relevantEvents: [Session] {
    return allEvents.filter { $0.type != .sessions }
  }

  override func matches(query: String) -> [SearchResult] {
    var matches = super.matches(query: query)
    for i in 0 ..< matches.count {
      var match = matches[i]
      guard let session = match.wrappedItem as? Session else { continue }
      let sessionTimeInterval =
        OtherEventsSearchResultProvider.dateIntervalFormatter.string(from: session.startTimestamp,
                                                                     to: session.endTimestamp)
      match.subtext = sessionTimeInterval
      matches[i] = match
    }
    return matches
  }

}
