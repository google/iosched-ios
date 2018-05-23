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
import Domain
import GoogleSignIn
import Firebase

final class DefaultWritableUserState: WritableUserState {

  fileprivate let bookmarkRepository: BookmarkRepository
  fileprivate let fcmRegistrationService: FCMRegistrationService
  fileprivate let userRegistrationService: UserRegistrationService

  public var isUserRegistered: Bool = false {
    didSet {
      NotificationCenter.default.post(Notification(name: .userRegistrationStateDidUpdate))
    }
  }

  init(bookmarkRepository: BookmarkRepository, fcmRegistrationService: FCMRegistrationService, userRegistrationService: UserRegistrationService) {
    self.bookmarkRepository = bookmarkRepository
    self.fcmRegistrationService = fcmRegistrationService
    self.userRegistrationService = userRegistrationService
  }

}

// MARK: - User Registration status

extension DefaultWritableUserState {

  func updateUserRegistrationStatus() {
    guard let user = Auth.auth().currentUser else {
      self.isUserRegistered = false
      return
    }
    user.getIDToken { (token, _) in
      guard let token = token else { return }
      self.userRegistrationService.isUserRegistered(idToken: token) { isRegistered in
        self.isUserRegistered = isRegistered
      }
    }
  }
}

// MARK: - Submitted Feedback

extension DefaultWritableUserState {

  private enum FeedbackConstants {
    static let submittedFeedbackKey = "com.google.iosched.submittedFeedback"
  }

  private var submittedFeedback: [String: Bool]? {
    return UserDefaults.standard.dictionary(forKey: FeedbackConstants.submittedFeedbackKey)
        as? [String: Bool]
  }

  func didSubmitFeedback(forSessionWithID id: String) -> Bool {
    return submittedFeedback?[id] ?? false
  }

  func setFeedbackSubmitted(_ submitted: Bool, forSessionWithID id: String) {
    var dict = submittedFeedback ?? [:]
    dict[id] = submitted
    UserDefaults.standard.set(dict, forKey: FeedbackConstants.submittedFeedbackKey)
  }

}

// MARK: - Settings / Notifications

extension DefaultWritableUserState {

  private enum SettingsConstants {
    static let notificationsEnabledKey = "com.google.iosched.isNotificationsEnabled"
    static let eventsInPacificTimeKey  = "com.google.iosched.isEventsInPacificTime"
    static let analyticsEnabledKey     = "com.google.iosched.isAnalyticsEnabled"
    static let bookmarkNotificationSuppressedKey = "com.google.iosched.isBookmarkSuppressed"
    static let unbookmarkNotificationSuppressedKey = "com.google.iosched.isUnbookmarkSuppressed"
  }

  var isEventsInPacificTime: Bool {
    return UserDefaults.standard.bool(forKey: SettingsConstants.eventsInPacificTimeKey)
  }

  func setEventsInPacificTime(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: SettingsConstants.eventsInPacificTimeKey)

    NotificationCenter.default.post(name: .timezoneUpdate,
        object: nil,
        userInfo: [:])
  }

  var isNotificationsEnabled: Bool {
    return UserDefaults.standard.bool(forKey: SettingsConstants.notificationsEnabledKey)
  }

  func setNotificationsEnabled(_ value: Bool) {
    // We write to userdefaults because analytics doesn't provide a way to read
    // the persisted value, only to write it.
    UserDefaults.standard.set(value, forKey: SettingsConstants.notificationsEnabledKey)
    AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(value)
  }

  var isAnalyticsEnabled: Bool {
    return UserDefaults.standard.bool(forKey: SettingsConstants.analyticsEnabledKey)
  }

  func setAnalyticsEnabled(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: SettingsConstants.analyticsEnabledKey)
  }

  var isBookmarkNotificationSuppressed: Bool {
    return UserDefaults.standard.bool(forKey: SettingsConstants.bookmarkNotificationSuppressedKey)
  }

  func setBookmarkNotificationSuppressed(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: SettingsConstants.bookmarkNotificationSuppressedKey)
  }

  var isUnbookmarkNotificationSuppressed: Bool {
    return UserDefaults.standard.bool(forKey: SettingsConstants.unbookmarkNotificationSuppressedKey)
  }

  func setUnbookmarkNotificationSuppressed(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: SettingsConstants.unbookmarkNotificationSuppressedKey)
  }

}

// MARK: - Onboarding

extension DefaultWritableUserState {

  private enum OnboardingConstants {
    static let acceptedTermsAndConditions = "AcceptedTermsAndConditionsKey"
    static let onboardingCompleted = "OnboardingCompletedKey"
    static let initialTooltipsShown = "InitialTooltipsShownKey"
  }

  var shouldDisplayOnboarding: Bool {
    return !isOnboardingCompleted()
  }

  var shouldShowInitialTooltips: Bool {
  return !isInitialTooltipsShown()
  }

  func isOnboardingCompleted() -> Bool {
    return UserDefaults.standard.bool(forKey: OnboardingConstants.onboardingCompleted)
  }

  func setOnboardingCompleted(_ completed: Bool) {
    UserDefaults.standard.set(completed, forKey: OnboardingConstants.onboardingCompleted)
    registerForSyncMessages()
  }

  func isAcceptedTermsAndConditions() -> Bool {
    return UserDefaults.standard.bool(forKey: OnboardingConstants.acceptedTermsAndConditions)
  }

  func setAcceptedTermsAndConditions(_ accepted: Bool) {
    UserDefaults.standard.set(accepted, forKey: OnboardingConstants.acceptedTermsAndConditions)
  }

  func isInitialTooltipsShown() -> Bool {
    return UserDefaults.standard.bool(forKey: OnboardingConstants.initialTooltipsShown)
  }

  func setInitialTooltipsShown(_ shown: Bool) {
    UserDefaults.standard.set(shown, forKey: OnboardingConstants.initialTooltipsShown)
  }

}

// MARK: - Sign in

extension DefaultWritableUserState {

  var isUserSignedIn: Bool {
    return GIDSignIn.sharedInstance().currentUser != nil
  }

  var signedInUser: Domain.User? {
    guard isUserSignedIn else { return nil }
    guard let googleUser = GIDSignIn.sharedInstance().currentUser else { return nil }
    guard let user = User(user: googleUser) else { return nil }
    return user
  }

  func signOut() {
    GIDSignIn.sharedInstance().signOut()
    purgeUserData()
  }

  private func purgeUserData(thorough: Bool = false) {
    // only if a thorough purge is requested, we will reset the user's onboarding status
    if thorough {
      resetOnboardingState()
    }
    setUserDismissedSignInPrompt(false)
    setUserSkippedSignInPrompt(false)
    purgeBookmarks()
  }

  private func resetOnboardingState() {
    setOnboardingCompleted(false)
    setAcceptedTermsAndConditions(false)
  }

  private func purgeBookmarks() {
    bookmarkRepository.purgeLocalBookmarks()
    doUpdate()
  }

  private func doUpdate() {
    NotificationCenter.default.post(name: .bookmarkUpdate,
                                    object: nil,
                                    userInfo: [:])
  }

}

// MARK: - Prompt cards

extension DefaultWritableUserState {

  private enum PromptCardConstants {
    static let userDismissedSignInPrompt = "UserDismissedSignInPrompt"
    static let userSkippedSignInPrompt = "UserSkippedSignInPrompt"
  }

  var isUserDismissedSignInPrompt: Bool {
    return UserDefaults.standard.bool(forKey: PromptCardConstants.userDismissedSignInPrompt)
  }

  func setUserDismissedSignInPrompt(_ dismissed: Bool) {
    UserDefaults.standard.set(dismissed, forKey: PromptCardConstants.userDismissedSignInPrompt)
  }

  var isUserSkippedSignInPrompt: Bool {
    return UserDefaults.standard.bool(forKey: PromptCardConstants.userSkippedSignInPrompt)
  }

  func setUserSkippedSignInPrompt(_ skipped: Bool) {
    UserDefaults.standard.set(skipped, forKey: PromptCardConstants.userSkippedSignInPrompt)
  }

}

extension DefaultWritableUserState {
  func registerForSyncMessages() {
    guard let deviceId = InstanceID.instanceID().token() else { return }

    fcmRegistrationService.register(device: deviceId)
  }

}
