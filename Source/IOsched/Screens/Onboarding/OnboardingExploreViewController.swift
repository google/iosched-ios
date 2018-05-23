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

class OnboardingExploreViewController: BaseOnboardingViewController {

  override var titleText: String {
    return NSLocalizedString("Explore I/O",
                             comment: "Short title explaining the Explore feature.")
  }

  override var subtitleText: String {
    return NSLocalizedString("Scan signposts to explore the conference venue in AR.",
                             comment: "Short promotional text describing how to use the Explore feature.")
  }

  override var nextButtonTitle: String {
    return NSLocalizedString("Get started",
                             comment: "Text for button that exits the onboarding flow.")
  }

  override func nextButtonPressed(_ sender: Any) {
    viewModel.finishOnboardingFlow()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if let countdown = headerView as? CountdownView {
      countdown.play()
    }
  }

  override func setupHeaderView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "onboarding_explore")
    imageView.image = image
    imageView.contentMode = .bottom
    imageView.setContentHuggingPriority(.required, for: .vertical)
    return imageView
  }

}
