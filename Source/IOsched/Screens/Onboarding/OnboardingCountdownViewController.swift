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
import FirebaseAuth
import Platform

class OnboardingCountdownViewController: BaseOnboardingViewController {

  override var titleText: String {
    return NSLocalizedString("Watch I/O live",
                             comment: "Tells users to watch the livestreams")
  }

  override var subtitleText: String {
    return NSLocalizedString("Join us online. We'll be streaming the keynotes and most sessions live.",
                             comment: "Tells users again to watch the livestreams")
  }

  override var nextButtonTitle: String {
    return NSLocalizedString("Get started",
                             comment: "Exits the onboarding flow")
  }

  override func nextButtonPressed(_ sender: Any) {
    signIn()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if let countdown = headerView as? CountdownView {
      countdown.play()
    }
  }

  override func setupHeaderView() -> CountdownView {
    let view = CountdownView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  deinit {
    if let countdown = headerView as? CountdownView {
      countdown.stop()
    }
  }

}

extension OnboardingCountdownViewController {

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
