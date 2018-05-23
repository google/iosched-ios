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
    return NSLocalizedString("Build your own schedule",
                             comment: "Describes the core functionality of the app")
  }

  override var subtitleText: String {
    return NSLocalizedString("Customize your I/O experience and reserve seats if you’re an attendee.",
                             comment: "Tells the user that reservations are a feature")
  }

  override var nextButtonTitle: String {
    return NSLocalizedString("Next", comment: "Navigates to the next onboarding screen")
  }

  override func setupHeaderView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "onboarding_schedule")
    imageView.image = image
    imageView.contentMode = .scaleAspectFill
    return imageView
  }

  override func nextButtonPressed(_ sender: Any) {
    viewModel.navigateToCountdown()
  }

}
