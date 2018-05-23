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

class OnboardingSessionsViewController: BaseOnboardingViewController {

// MARK: - View setup

  override var titleText: String {
    return NSLocalizedString("Sign in to receive I/O notifications and reserve seats for sessions.",
                             comment: "Onboarding text encouraging users to sign in")
  }

  override var subtitleText: String {
    return ""
  }

  override var nextButtonTitle: String {
    return NSLocalizedString("Sign In", comment: "Button presenting a sign-in prompt.")
  }

  override func setupHeaderView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "onboarding_signin")
    imageView.image = image
    imageView.contentMode = .bottom
    imageView.setContentHuggingPriority(.required, for: .vertical)
    return imageView
  }

  override func nextButtonPressed(_ sender: Any) {
    signIn()
  }

}

extension OnboardingSessionsViewController {

  func signIn() {
    SignIn.sharedInstance.signIn { (user, error) in
      defer {
        self.viewModel.finishOnboardingFlow()
      }
      guard error == nil else {
        self.viewModel.signInFailed(withError: error!)
        return
      }
      if let user = user {
        self.viewModel.signInSuccessful(user: user)
      }
    }
  }

}
