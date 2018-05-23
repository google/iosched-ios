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
import Lottie
import MaterialComponents
import DTCoreText

class BaseOnboardingViewController: UIViewController {

  lazy var headerView: UIView = self.setupHeaderView()
  lazy var titleLabel: UILabel = self.setupTitleLabel()
  lazy var subtitleLabel: UILabel = self.setupSubtitleLabel()
  lazy var nextButton: MDCButton = self.setupNextButton()

  let viewModel: OnboardingViewModel

  init(viewModel: OnboardingViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

// MARK: - View setup

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    view.addSubview(headerView)
    view.addSubview(nextButton)
    view.addSubview(subtitleLabel)
    view.addSubview(titleLabel)

    view.addConstraints(headerViewConstraints)
    view.addConstraints(nextButtonConstraints)
    view.addConstraints(subtitleLabelConstraints)
    view.addConstraints(titleLabelConstraints)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if UIAccessibilityIsVoiceOverRunning() {
      UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, titleLabel)
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }

  func setupHeaderView() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  var titleText: String {
    return "Welcome to Google I/O"
  }

  func setupTitleLabel() -> UILabel {
    let label = UILabel()
    let font = UIFont.preferredFont(forTextStyle: .title1)
    label.font = font
    label.numberOfLines = 1
    label.textColor = UIColor(hex: "#424242")
    label.text = titleText
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }

  var subtitleText: String {
    return "May 8-10, 2018\nMountain View, CA"
  }

  func setupSubtitleLabel() -> UILabel {
    let label = UILabel()
    let font = UIFont.preferredFont(forTextStyle: .body)
    label.font = font
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.textColor = UIColor(hex: "#424242")
    label.text = subtitleText
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }

  var nextButtonTitle: String {
    return "Next"
  }

  func setupNextButton() -> MDCButton {
    let button = MDCButton()
    button.setTitle(nextButtonTitle, for: .normal)
    button.setBackgroundColor(UIColor(hex: "#536dfe"))
    button.setTitleColor(.white, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isUppercaseTitle = false
    button.setContentHuggingPriority(.defaultHigh, for: .vertical)
    button.addTarget(self, action: #selector(nextButtonPressed(_:)), for: .touchUpInside)
    button.setContentCompressionResistancePriority(.required, for: .vertical)
    return button
  }

  var headerViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: headerView, attribute: .left,
                         relatedBy: .equal,
                         toItem: view, attribute: .left,
                         multiplier: 1,
                         constant: 75),
      NSLayoutConstraint(item: headerView, attribute: .right,
                         relatedBy: .equal,
                         toItem: view, attribute: .right,
                         multiplier: 1,
                         constant: -75),
      NSLayoutConstraint(item: headerView, attribute: .top,
                         relatedBy: .equal,
                         toItem: view, attribute: .top,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: headerView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: titleLabel, attribute: .top,
                         multiplier: 1,
                         constant: 0)
    ]
  }

  var titleLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: titleLabel, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: view, attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: titleLabel, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: subtitleLabel, attribute: .top,
                         multiplier: 1,
                         constant: -32)
    ]
  }

  var subtitleLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: subtitleLabel, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: view, attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: subtitleLabel, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: nextButton, attribute: .top,
                         multiplier: 1,
                         constant: -32),
      NSLayoutConstraint(item: subtitleLabel, attribute: .width,
                         relatedBy: .lessThanOrEqual,
                         toItem: view, attribute: .width,
                         multiplier: 1,
                         constant: -64)
    ]
  }

  var nextButtonConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: nextButton, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: view, attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: nextButton, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: view, attribute: .bottom,
                         multiplier: 1,
                         constant: -25)
    ]
  }

  @objc func nextButtonPressed(_ sender: Any) {
    // Override this function.
  }

}
