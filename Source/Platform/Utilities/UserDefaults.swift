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

import Firebase

extension UserDefaults {

  enum Settings {
    static let notificationsEnabledKey = "com.google.iosched.isNotificationsEnabled"
    static let eventsInPacificTimeKey  = "com.google.iosched.shouldDisplayEventsInPDT"
    static let analyticsEnabledKey     = "com.google.iosched.isAnalyticsEnabled"
  }

  enum Onboarding {
    static let onboardingCompleted = "com.google.iosched.onboardingCompleted"
  }

  var shouldDisplayEventsInPDT: Bool {
    return bool(forKey: Settings.eventsInPacificTimeKey)
  }

  func setShouldDisplayEventsInPDT(_ value: Bool) {
    set(value, forKey: Settings.eventsInPacificTimeKey)

    NotificationCenter.default.post(name: .timezoneUpdate,
                                    object: nil,
                                    userInfo: [:])
  }

  var isNotificationsEnabled: Bool {
    return bool(forKey: UserDefaults.Settings.notificationsEnabledKey)
  }

  func setNotificationsEnabled(_ value: Bool) {
    set(value, forKey: UserDefaults.Settings.notificationsEnabledKey)
  }

  var isAnalyticsEnabled: Bool {
    return bool(forKey: UserDefaults.Settings.analyticsEnabledKey)
  }

  func setAnalyticsEnabled(_ value: Bool) {
    set(value, forKey: UserDefaults.Settings.analyticsEnabledKey)
    Analytics.setAnalyticsCollectionEnabled(value)
  }

}
