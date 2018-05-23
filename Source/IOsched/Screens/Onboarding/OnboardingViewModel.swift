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

  func signInSuccessful(user: GIDGoogleUser) {
    serviceLocator.updateConferenceData { }
    navigator?.showLoginSuccessfulMessage(user: user)
  }

  func signInFailed(withError error: Error) {
    let nserror = error as NSError
    let errorCode = GIDSignInErrorCode(rawValue: nserror.code)

    if errorCode != .canceled {
      navigator?.showLoginFailedMessage()
    }
  }

  func finishOnboardingFlow() {
    serviceLocator.userState.setOnboardingCompleted(true)
    notificationPermissions.setNotificationsEnabled(true) { (_) in }
    navigator?.navigateToMainNavigation()
    navigator = nil
  }

}
