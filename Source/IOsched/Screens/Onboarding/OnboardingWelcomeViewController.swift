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
import Lottie

class OnboardingWelcomeViewController: BaseOnboardingViewController {

// MARK: - View setup

  @objc override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  private var image: UIImage? {
    let relativeDate = IODateComparer.currentDateRelativeToIO()
    switch relativeDate {
    case .before:
      return UIImage(named: "onboarding_pre")
    case .during, .after:
      return UIImage(named: "onboarding_during_post")
    }
  }

  override func setupHeaderView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "onboarding_pre")
    imageView.image = image
    imageView.contentMode = .bottom
    imageView.setContentHuggingPriority(.required, for: .vertical)
    return imageView
  }

  override var titleText: String {
    let relativeDate = IODateComparer.currentDateRelativeToIO()
    switch relativeDate {
    case .before:
      return NSLocalizedString("Google I/O is coming",
                               comment: "Welcome text presented in the onboarding flow before I/O begins")
    case .during:
      return NSLocalizedString("Google I/O",
                               comment: "Welcome text presented in the onboarding flow during I/O")
    case .after:
      return NSLocalizedString("Watch the I/O '19 recap and checkout #io19 on social",
                               comment: "Welcome text presented in the onboarding flow after I/O ends")
    }

  }

  override var subtitleText: String {
    let relativeDate = IODateComparer.currentDateRelativeToIO()
    switch relativeDate {
    case .before, .during:
      return NSLocalizedString("May 7-9, 2019\nMountain View, CA",
                               comment: "Date and location for Google I/O")
    case .after:
      return ""
    }
  }

  override var nextButtonTitle: String {
    return NSLocalizedString("Next", comment: "Navigates to the next onboarding screen")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let animationView = headerView as? AnimationView {
      animationView.play()
    }
  }

  override func nextButtonPressed(_ sender: Any) {
    viewModel.navigateToSchedule()
  }

}
