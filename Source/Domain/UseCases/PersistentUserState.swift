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

// Constants for NotificationCenter updates
public extension Notification.Name {
  static let timezoneUpdate = Notification.Name("com.google.iosched.timezoneUpdate")
  static let userRegistrationStateDidUpdate =
      Notification.Name("com.iosched.userRegistrationStateDidUpdate")
}

/// A class representing writable user state, such as whether or not the user has completed
/// the onboarding flow or whether or not the user is registered for notifications.
/// The only concrete implementation of this class is DefaultPersistentUserState.
/// - SeeAlso: DefaultPersistentUserState
public protocol PersistentUserState {

  /// A boolean representing the user's attendee registration status. Returns true if the user
  /// is a registered attendee, false otherwise.
  var isUserRegistered: Bool { get }

  /// A convenience method returning whether or not the onboarding flow should be displayed
  /// at first launch.
  /// - SeeAlso: isOnboardingCompleted()
  var shouldDisplayOnboarding: Bool { get }

  /// Returns true if the onboarding flow has been completed, false otherwise.
  func isOnboardingCompleted() -> Bool

  /// Sets the onboarding flow completion boolean flag, which persists between launches.
  func setOnboardingCompleted(_ completed: Bool)

  /// Returns true if the user is signed in, false otherwise.
  var isUserSignedIn: Bool { get }

  /// Returns the currently logged in user, or nil if there is no user logged in.
  var signedInUser: User? { get }

  /// Signs out the currently logged in user. Does nothing if there is no logged in user.
  func signOut()

  /// Returns true if the user has set all conference times to be shown in PDT, false otherwise.
  var shouldDisplayEventsInPDT: Bool { get }

  /// Returns true if the user has enabled notifications and their associated permissions,
  /// false otherwise.
  var isNotificationsEnabled: Bool { get }

  /// Returns true if the user has not opted out of analytics.
  var isAnalyticsEnabled: Bool { get }

  /// Sets the flag to display events in PDT instead of the user's device time zone.
  func setShouldDisplayEventsInPDT(_ value: Bool)

  /// Sets a flag enabling or disabling notifications.
  func setNotificationsEnabled(_ value: Bool)

  /// Sets a flag enabling or disabling analytics.
  func setAnalyticsEnabled(_ value: Bool)

  /// Writes the device's FCM token to the backend, where it will be registered for notifications.
  func registerForFCM()

  /// Fetches the user's registration information from the backend and writes it locally.
  func updateUserRegistrationStatus()

  /// A boolean flag per session ID tracking whether or not the user has submitted feedback
  /// for the particular session.
  func didSubmitFeedback(forSessionWithID: String) -> Bool

  /// Sets the boolean flag per session ID indicating the session has already been reviewed.
  func setFeedbackSubmitted(_ submitted: Bool, forSessionWithID: String)

}
