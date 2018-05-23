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
import DTCoreText
import Lottie

class OnboardingWelcomeViewController: BaseOnboardingViewController {

// MARK: - View setup

  @objc override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  var animationFileName: String {
    return "IO18_Logo"
  }

  override func setupHeaderView() -> LOTAnimationView {
    let animationView = LOTAnimationView(name: animationFileName)
    animationView.loopAnimation = true
    animationView.contentMode = .scaleAspectFit
    animationView.translatesAutoresizingMaskIntoConstraints = false
    return animationView
  }

  override var titleText: String {
    return NSLocalizedString("Welcome to Google I/O",
                             comment: "Welcome text presented in the onboarding flow")
  }

  override var subtitleText: String {
    return NSLocalizedString("May 8-10\nMountain View, CA",
                             comment: "Date and location for Google I/O")
  }

  override var nextButtonTitle: String {
    return NSLocalizedString("Next", comment: "Navigates to the next onboarding screen")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let animationView = headerView as? LOTAnimationView {
      animationView.play()
    }
  }

  override func nextButtonPressed(_ sender: Any) {
    viewModel.navigateToSchedule()
  }

}
