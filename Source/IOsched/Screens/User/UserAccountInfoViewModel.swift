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
import MaterialComponents
import GoogleSignIn

final class UserAccountInfoViewModel {

  fileprivate enum Constants {
    static let signOutButtonLabel = NSLocalizedString("Sign out", comment: "Sign Out button")
    static let signInButtonLabel = NSLocalizedString("Sign in", comment: "Sign in button")
  }

  fileprivate enum Messages {
    static let signedInAttendeeText =
      NSLocalizedString("As a signed in attendee, your saved events and reserved sessions are synced to your account across app and site. You can provide session feedback after sessions end.", comment: "Explanation of benefits of being signed in attendee")

    static let signedInText = NSLocalizedString("Your saved events are synced to your account across app and site. You can provide session feedback after sessions end.", comment:"Explanation of benefits of being signed in user")

    static let signedOutText =
      NSLocalizedString("Sign in to save events, reserve seats and rate sessions (if an attendee). Actions will be synced from your account across app and site.", comment: "Explanation of why users should sign in")
  }

  // MARK: - Dependencies
  private let userState: WritableUserState
  private let navigator: SignInNavigatable

  // MARK: - Input

  // MARK: - Output
  var userNameText: String?
  var userEmailText: String?
  var thumbnailUrl: String?
  var messageText: String?
  var actionButtonText: String?
  var isSignedIn: Bool = false

  init(userState: WritableUserState, navigator: SignInNavigatable) {
    self.userState = userState
    self.navigator = navigator
    updateModel()
  }

  // MARK: - View updates

  // MARK: - Model updates
  func updateModel() {
    if userState.isUserSignedIn {
      let user = userState.signedInUser
      userNameText = user?.name
      userEmailText = user?.email
      thumbnailUrl = user?.thumbnailUrl
      messageText = userState.isUserRegistered ?
        Messages.signedInAttendeeText : Messages.signedInText
      actionButtonText = Constants.signOutButtonLabel
      isSignedIn = true
    } else {
      userNameText = "Sign in to customize your schedule"
      userEmailText = ""
      thumbnailUrl = ""
      messageText = Messages.signedOutText
      actionButtonText = Constants.signInButtonLabel
      isSignedIn = false
    }
  }

  // MARK: - Actions
  func signIn() {
  }

  func signOut(completion: (() -> Void)? = nil) {
    SignIn.sharedInstance.signOut()
    userState.signOut()
    completion?()
  }

  func signInSuccessful(user: GIDGoogleUser) {
    userState.setOnboardingCompleted(true)
    navigator.showLoginSuccessfulMessage(user: user)
  }

  func signInFailed(withError error: Error) {
    let nserror = error as NSError
    let errorCode = GIDSignInErrorCode(rawValue: nserror.code)
    if errorCode == .canceled {
      navigator.showLoginFailedMessage()
    }
  }

}
