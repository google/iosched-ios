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

import UIKit
import GoogleSignIn
import MaterialComponents

protocol SignInNavigatable {
  func showLoginSuccessfulMessage(user: GIDGoogleUser)
  func showLoginFailedMessage()
}

private enum Constants {
  static let signInSuccessful =
    NSLocalizedString("Signed in",
                      comment: "Text for snackbar confirming successful login (w/o email)")
  static let signInCanceled =
    NSLocalizedString("Sign in canceled.",
                      comment: "Sign in canceled by user")
}

extension SignInNavigatable {

  func showLoginSuccessfulMessage(user: GIDGoogleUser) {
    var signedInText: String
    if let email = user.profile.email {
      signedInText = NSLocalizedString("Signed in as \(email).",
        comment: "Text for snackbar confirming successful login")
    }
    else {
      signedInText = Constants.signInSuccessful
    }
    let message = MDCSnackbarMessage(text: signedInText)
    MDCSnackbarManager.show(message)
  }

  func showLoginFailedMessage() {
    let message = MDCSnackbarMessage(text: Constants.signInCanceled)
    MDCSnackbarManager.show(message)
  }

}
