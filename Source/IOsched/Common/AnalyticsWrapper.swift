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

enum AnalyticsParameters {

  // Screens
  static let myEvents = "My Events"
  static let schedule = "Schedule"
  static let feed = "Feed"
  static let map = "Map"
  static let info = "Info"

  static let infoEvent = "Info: Event"
  static let infoTravel = "Info: Travel"
  static let infoFAQ = "Info: FAQ"
  static let infoSettings = "Info: Settings"

  // Items
  static let sessionReserved = "Session reserved"

  static func itemID(forPinTitle title: String) -> String {
    return "Pin: \(title)"
  }

  static func itemID(forSessionTitle title: String) -> String {
    return "Session: \(title)"
  }

  static func itemID(forSelectedDay day: Int) -> String {
    return "Schedule for Day \(day)"
  }

  static func itemID(forSelectedFilter filter: String) -> String {
    return "Filtered on \(filter)"
  }

  static func itemID(forSpeakerName name: String) -> String {
    return "Speaker: \(name)"
  }

  // Content types
  static let uiEvent = "ui event"
  static let screen = "screen"

  // Custom parameters
  static let uiAction = "ui_action"

  // UI Actions
  static let primaryNavClick = "primary nav click"
  static let viewSessions = "view sessions"
  static let viewMaps = "view maps"
  static let mapPinSelect = "map pin select"
  static let bookmarked = "bookmarked"
  static let filterUsed = "topnav filter used"
  static let reservation = "reservation"

  // User property names
  static let userLoggedIn = "user_logged_in"

}

final class AnalyticsWrapper {

  let userState: PersistentUserState

  init(userState: PersistentUserState) {
    self.userState = userState
  }

  private var canLogEvents: Bool {
    return userState.isAnalyticsEnabled
  }

  func logEvent(_ name: String, parameters: [String: Any]? = nil) {
    guard canLogEvents else { return }
    Analytics.logEvent(name, parameters: parameters)
  }

  func setUserProperty(_ property: String?, forName name: String) {
    Analytics.setUserProperty(property, forName: name)
  }

  func setUserID(_ id: String?) {
    Analytics.setUserID(id)
  }

  func setScreenName(_ screenName: String?, screenClass: String?) {
    Analytics.setScreenName(screenName, screenClass: screenClass)
  }

  func handleEvents(forBackgroundURLSession identifier: String, completionHandler: @escaping (() -> Void)) {
    Analytics.handleEvents(forBackgroundURLSession: identifier, completionHandler: completionHandler)
  }

  func handleOpen(_ url: URL) {
    Analytics.handleOpen(url)
  }

  func handleUserActivity(_ userActivity: Any) {
    Analytics.handleUserActivity(userActivity)
  }

}

protocol LoggableRootController {

  var screenName: String? { get }

}
