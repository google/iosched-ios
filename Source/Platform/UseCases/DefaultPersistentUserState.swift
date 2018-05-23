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

import GoogleSignIn
import FirebaseAuth
import FirebaseMessaging

final class DefaultPersistentUserState: PersistentUserState {

  fileprivate let fcmRegistrationService: FCMRegistrationService
  fileprivate let userRegistrationService: UserRegistrationService
  fileprivate let signIn: SignInInterface

  public var isUserRegistered: Bool = false {
    didSet {
      NotificationCenter.default.post(Notification(name: .userRegistrationStateDidUpdate))
    }
  }

  init(fcmRegistrationService: FCMRegistrationService,
       userRegistrationService: UserRegistrationService,
       signIn: SignInInterface = SignIn.sharedInstance) {
    self.fcmRegistrationService = fcmRegistrationService
    self.userRegistrationService = userRegistrationService
    self.signIn = signIn
  }

}

// MARK: - User Registration status

extension DefaultPersistentUserState {

  func updateUserRegistrationStatus() {
    // TODO(morganchen): replace this with SignIn
    guard let user = signIn.currentUpgradableUser else {
      self.isUserRegistered = false
      return
    }
    user.fetchIDToken { (token, _) in
      guard let token = token else { return }
      self.userRegistrationService.isUserRegistered(idToken: token) { isRegistered in
        self.isUserRegistered = isRegistered
      }
    }
  }
}

// MARK: - Submitted Feedback

extension DefaultPersistentUserState {

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

extension DefaultPersistentUserState {

  var shouldDisplayEventsInPDT: Bool {
    return UserDefaults.standard.shouldDisplayEventsInPDT
  }

  func setShouldDisplayEventsInPDT(_ value: Bool) {
    UserDefaults.standard.setShouldDisplayEventsInPDT(value)
  }

  var isNotificationsEnabled: Bool {
    return UserDefaults.standard.isNotificationsEnabled
  }

  func setNotificationsEnabled(_ value: Bool) {
    UserDefaults.standard.setNotificationsEnabled(value)
  }

  var isAnalyticsEnabled: Bool {
    return UserDefaults.standard.isAnalyticsEnabled
  }

  func setAnalyticsEnabled(_ value: Bool) {
    UserDefaults.standard.setAnalyticsEnabled(value)
  }

}

// MARK: - Onboarding

extension DefaultPersistentUserState {

  var shouldDisplayOnboarding: Bool {
    return !isOnboardingCompleted()
  }

  func isOnboardingCompleted() -> Bool {
    return UserDefaults.standard.bool(forKey: UserDefaults.Onboarding.onboardingCompleted)
  }

  func setOnboardingCompleted(_ completed: Bool) {
    UserDefaults.standard.set(completed, forKey: UserDefaults.Onboarding.onboardingCompleted)
  }

}

// MARK: - Sign in

extension DefaultPersistentUserState {

  var isUserSignedIn: Bool {
    return signIn.currentUser != nil
  }

  var signedInUser: User? {
    guard isUserSignedIn else { return nil }
    guard let googleUser = GIDSignIn.sharedInstance().currentUser else { return nil }
    guard let user = User(user: googleUser) else { return nil }
    return user
  }

  func signOut() {
    GIDSignIn.sharedInstance().signOut()
    purgeUserData()
  }

  private func purgeUserData() {
    postUpdateNotification()
  }

  private func resetOnboardingState() {
    setOnboardingCompleted(false)
  }

  private func postUpdateNotification() {
    NotificationCenter.default.post(name: .bookmarkUpdate,
                                    object: nil,
                                    userInfo: [:])
  }

}

extension DefaultPersistentUserState {
  func registerForFCM() {
    guard let deviceId = Messaging.messaging().fcmToken else { return }
    fcmRegistrationService.register(device: deviceId)
  }

}
