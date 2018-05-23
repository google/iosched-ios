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
import Platform
import MaterialComponents
import FirebaseAuth
import GoogleSignIn

class OnboardingViewModel {

  // MARK: - Dependencies
  private var navigator: OnboardingNavigator?
  private let notificationPermissions: NotificationPermissions
  private let serviceLocator: ServiceLocator

  init(serviceLocator: ServiceLocator,
       navigator: OnboardingNavigator) {
    self.navigator = navigator
    self.serviceLocator = serviceLocator
    self.notificationPermissions = NotificationPermissions(userState: serviceLocator.userState,
                                                           application: .shared)
  }

  // MARK: - Actions

  func navigateToSchedule() {
    navigator?.navigateToSchedule()
  }

  func navigateToCountdown() {
    self.navigator?.navigateToCountdown()
  }

  func signInSuccessful(user: GIDGoogleUser) {
    serviceLocator.updateConferenceData { }
    navigator?.showLoginSuccessfulMessage(user: user)
    navigator?.navigateToMainNavigation()
  }

  func signInFailed(withError error: Error) {
    let nserror = error as NSError
    let errorCode = GIDSignInErrorCode(rawValue: nserror.code)

    // Only sign in anonymously if login fails. Otherwise, just use the google user.
    Auth.auth().signInAnonymously { (user, error) in
      if let error = error {
        print("Auth Error: Anonymous Sign-in failed. The app is not usable if anonymous login doesn't succeed. \(error)")
      } else {
        let description = user.flatMap(String.init(describing:)) ?? "(null)"
        print("Signed in anonymously with user: \(description)")
        self.serviceLocator.updateConferenceData { }
      }
    }

    if errorCode == .canceled {
      // continue on manual cancellation.
      navigator?.navigateToMainNavigation()
    } else {
      navigator?.showLoginFailedMessage()
    }
  }

  func finishOnboardingFlow() {
    serviceLocator.userState.setAcceptedTermsAndConditions(true)
    serviceLocator.userState.setOnboardingCompleted(true)
    notificationPermissions.setNotificationsEnabled(true) { (_) in }
    navigator?.navigateToMainNavigation()
    navigator = nil
  }

}
