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

private enum TimeZoneConstants {
  static let pacificTimeZone = TimeUtils.pacificTimeZone
}

public class TimeZoneAwareCalendar: NSCalendar {

  public override init?(calendarIdentifier ident: NSCalendar.Identifier) {
    super.init(calendarIdentifier: ident)
    updateTimeZone()
    registerForTimezoneUpdates()
  }

  @available(*, unavailable)
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateTimeZone() {
    self.timeZone = TimeZone.userTimeZone()
  }

  private var timezoneObserver: Any? {
    willSet {
      if let observer = timezoneObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  private func registerForTimezoneUpdates() {
    timezoneObserver = NotificationCenter.default.addObserver(forName: .timezoneUpdate,
                                                              object: nil,
                                                              queue: nil) { [weak self] _ in
      // update timezone
      self?.updateTimeZone()
    }
  }

}

public extension TimeZone {

  public static func userTimeZone() -> TimeZone {
    return UserDefaults.standard.isEventsInPacificTime
        ? TimeZoneConstants.pacificTimeZone
        : self.autoupdatingCurrent
  }
}
