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
import GoogleSignIn

final class UserAccountInfoViewModel {

  private enum Constants {
    static let signOutButtonLabel = NSLocalizedString("Sign out", comment: "Sign Out button")
    static let signInButtonLabel = NSLocalizedString("Sign in", comment: "Sign in button")
  }

  private enum Messages {
    static let signedInAttendeeText =
      NSLocalizedString("As a signed in attendee, your saved events and reserved sessions are synced to your account across app and site. You can provide session feedback after sessions end.", comment: "Explanation of benefits of being signed in attendee")

    static let signedInText = NSLocalizedString("Your saved events are synced to your account across app and site. You can provide session feedback after sessions end.", comment: "Explanation of benefits of being signed in user")

    static let signedOutText =
      NSLocalizedString("Sign in to save events, reserve seats and rate sessions (if an attendee). Actions will be synced from your account across app and site.", comment: "Explanation of why users should sign in")
  }

  // MARK: - Dependencies
  private let userState: PersistentUserState
  private let signIn: SignInInterface
  private let navigator = SignInBannerPresenter()

  // MARK: - Input

  // MARK: - Output
  private(set) var userNameText: String?
  private(set) var userEmailText: String?
  private(set) var thumbnailURL: String?
  private(set) var messageText: String?
  private(set) var actionButtonText: String?
  private(set) var isSignedIn = false

  init(userState: PersistentUserState, signIn: SignInInterface = SignIn.sharedInstance) {
    self.userState = userState
    self.signIn = signIn
    updateModel(signedIn: signIn.currentUser != nil)
    addSignInListeners()
  }

  // MARK: - View updates

  // MARK: - Model updates
  private func updateModel(signedIn: Bool) {
    isSignedIn = signedIn
    if signedIn {
      let user = userState.signedInUser
      userNameText = user?.name
      userEmailText = user?.email
      thumbnailURL = user?.thumbnailURL
      messageText = userState.isUserRegistered ?
        Messages.signedInAttendeeText : Messages.signedInText
      actionButtonText = Constants.signOutButtonLabel
    } else {
      userNameText = "Sign in to customize your schedule"
      userEmailText = ""
      thumbnailURL = ""
      messageText = Messages.signedOutText
      actionButtonText = Constants.signInButtonLabel
    }
  }

  private func addSignInListeners() {
    _ = signIn.addGoogleSignInHandler(self) { [weak self] in
      self?.updateModel(signedIn: true)
      self?.signInStateChangeCallback?(true)
    }
    _ = signIn.addGoogleSignOutHandler(self) { [weak self] in
      self?.updateModel(signedIn: false)
      self?.signInStateChangeCallback?(false)
    }
  }

  // MARK: - Actions

  func presentSignIn() {
    SignIn.sharedInstance.signIn { (user, error) in
      guard error == nil else {
        self.signInFailed(withError: error!)
        return
      }

      if let user = user {
        self.signInSuccessful(user: user)
      }
    }
  }

  func signOut() {
    userState.signOut()
    signIn.signOut()
  }

  var signInStateChangeCallback: ((Bool) -> Void)?

  private func signInSuccessful(user: GIDGoogleUser) {
    userState.setOnboardingCompleted(true)
    navigator.showLoginSuccessfulMessage(user: user)
  }

  private func signInFailed(withError error: Error) {
    let nserror = error as NSError
    let errorCode = GIDSignInErrorCode(rawValue: nserror.code)
    if errorCode == .canceled {
      navigator.showLoginFailedMessage()
    }
  }

}
