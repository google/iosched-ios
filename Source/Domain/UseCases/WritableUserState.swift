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
  public static let timezoneUpdate = Notification.Name("timezoneUpdate")
  public static let userRegistrationStateDidUpdate = Notification.Name("com.iosched.userRegistrationStateDidUpdate")
}

public protocol WritableUserState {

  var isUserRegistered: Bool { get }

  var shouldDisplayOnboarding: Bool { get }

  var shouldShowInitialTooltips: Bool { get }

  func isOnboardingCompleted() -> Bool
  func setOnboardingCompleted(_ completed: Bool)

  func isAcceptedTermsAndConditions() -> Bool
  func setAcceptedTermsAndConditions(_ accepted: Bool)

  func isInitialTooltipsShown() -> Bool
  func setInitialTooltipsShown(_ shown: Bool)

  var isUserSignedIn: Bool { get }
  var signedInUser: User? { get }
  func signOut()

  var isUserDismissedSignInPrompt: Bool { get }
  func setUserDismissedSignInPrompt(_ dismissed: Bool)
  var isUserSkippedSignInPrompt: Bool { get }
  func setUserSkippedSignInPrompt(_ skipped: Bool)

  var isEventsInPacificTime: Bool { get }
  var isNotificationsEnabled: Bool { get }
  var isAnalyticsEnabled: Bool { get }

  func setEventsInPacificTime(_ value: Bool)
  func setNotificationsEnabled(_ value: Bool)
  func setAnalyticsEnabled(_ value: Bool)

  var isBookmarkNotificationSuppressed: Bool { get }
  func setBookmarkNotificationSuppressed(_ value: Bool)
  var isUnbookmarkNotificationSuppressed: Bool { get }
  func setUnbookmarkNotificationSuppressed(_ value: Bool)

  func registerForSyncMessages()
  func updateUserRegistrationStatus()

  func didSubmitFeedback(forSessionWithID: String) -> Bool
  func setFeedbackSubmitted(_ submitted: Bool, forSessionWithID: String)

}
