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

class BaseOnboardingViewController: UIViewController {

  lazy var headerView: UIView = self.setupHeaderView()
  lazy var titleLabel: UILabel = self.setupTitleLabel()
  lazy var subtitleLabel: UILabel = self.setupSubtitleLabel()
  lazy var nextButton: MDCButton = self.setupNextButton()
  private lazy var skipButton: MDCButton = self.setupSkipButton()

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
    view.addSubview(skipButton)
    view.addSubview(titleStackContainerView)

    view.addConstraints(headerViewConstraints)
    view.addConstraints(nextButtonConstraints)
    view.addConstraints(titleStackContainerViewConstraints)
    view.addConstraints(skipButtonConstraints)
    titleStackContainerView.addConstraints(titleStackViewConstraints)

    titleLabel.preferredMaxLayoutWidth = view.frame.size.width - 48
    view.clipsToBounds = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if UIAccessibility.isVoiceOverRunning {
      UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: titleLabel)
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
    let font = ProductSans.regular.style(.title2)
    label.enableAdjustFontForContentSizeCategory()
    label.font = font
    label.numberOfLines = 0
    label.textColor = UIColor(red: 32 / 255, green: 33 / 255, blue: 36 / 255, alpha: 1)
    label.text = titleText
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }

  var subtitleText: String {
    // Placeholder string overridden in subclasses.
    return "May 7-9, 2019\nMountain View, CA"
  }

  func setupSubtitleLabel() -> UILabel {
    let label = UILabel()
    let font = ProductSans.regular.style(.title2)
    label.enableAdjustFontForContentSizeCategory()
    label.font = font
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.textColor = UIColor(red: 128 / 255, green: 134 / 255, blue: 139 / 255, alpha: 1)
    label.text = subtitleText
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }

  private lazy var titleStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(subtitleLabel)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }()

  private lazy var titleStackContainerView: UIView = {
    let view = UIView()
    view.addSubview(titleStackView)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  var nextButtonTitle: String {
    return "Next"
  }

  func setupNextButton() -> MDCButton {
    let button = MDCButton()
    button.setTitle(nextButtonTitle, for: .normal)
    button.setBackgroundColor(UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1))
    button.setTitleColor(.white, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isUppercaseTitle = false
    button.setContentHuggingPriority(.defaultHigh, for: .vertical)
    button.addTarget(self, action: #selector(nextButtonPressed(_:)), for: .touchUpInside)
    button.setContentCompressionResistancePriority(.required, for: .vertical)
    button.setContentHuggingPriority(.required, for: .vertical)
    return button
  }

  func setupSkipButton() -> MDCButton {
    let button = MDCFlatButton()
    let title = NSLocalizedString("Skip", comment: "Button text for skipping the onboarding flow")
    let hint = NSLocalizedString("Double-tap to skip the onboarding flow.",
                                 comment: "Accessibility hint for users to skip the onboarding flow")
    button.setTitle(title, for: .normal)
    button.accessibilityHint = hint
    button.setTitleColor(UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1),
                         for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isUppercaseTitle = false
    button.setContentHuggingPriority(.defaultHigh, for: .vertical)
    button.addTarget(self, action: #selector(skipButtonPressed(_:)), for: .touchUpInside)
    button.setContentCompressionResistancePriority(.required, for: .vertical)
    button.setContentHuggingPriority(.required, for: .vertical)
    return button
  }

  var headerViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: headerView, attribute: .left,
                         relatedBy: .equal,
                         toItem: view, attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: headerView, attribute: .right,
                         relatedBy: .equal,
                         toItem: view, attribute: .right,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: headerView, attribute: .top,
                         relatedBy: .equal,
                         toItem: view, attribute: .top,
                         multiplier: 1,
                         constant: 140),
      NSLayoutConstraint(item: headerView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: titleStackContainerView, attribute: .top,
                         multiplier: 1,
                         constant: -32),
      NSLayoutConstraint(item: headerView, attribute: .bottom,
                         relatedBy: .lessThanOrEqual,
                         toItem: titleStackView, attribute: .top,
                         multiplier: 1,
                         constant: -32)
    ]
  }

  var titleStackViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: titleStackView,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: titleStackContainerView,
                         attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: titleStackView,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: titleStackContainerView,
                         attribute: .right,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: titleStackView,
                         attribute: .centerY,
                         relatedBy: .equal,
                         toItem: titleStackContainerView,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 0)
    ]
  }

  var titleStackContainerViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: titleStackContainerView,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: view,
                         attribute: .left,
                         multiplier: 1,
                         constant: 24),
      NSLayoutConstraint(item: titleStackContainerView,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: view,
                         attribute: .right,
                         multiplier: 1,
                         constant: -24),
      NSLayoutConstraint(item: titleStackContainerView,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: nextButton,
                         attribute: .top,
                         multiplier: 1,
                         constant: -32)
    ]
  }

  var nextButtonConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: nextButton, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: view, attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: nextButton, attribute: .height,
                         relatedBy: .greaterThanOrEqual,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 48),
      NSLayoutConstraint(item: nextButton, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: view, attribute: .bottom,
                         multiplier: 1,
                         constant: -64)
    ]
  }

  private var skipButtonConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: skipButton, attribute: .top,
                         relatedBy: .equal,
                         toItem: topLayoutGuide, attribute: .bottom,
                         multiplier: 1, constant: 4),
      NSLayoutConstraint(item: skipButton, attribute: .trailing,
                         relatedBy: .equal,
                         toItem: view, attribute: .trailing,
                         multiplier: 1, constant: -4),
      NSLayoutConstraint(item: skipButton, attribute: .height,
                         relatedBy: .greaterThanOrEqual,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: 48)
    ]
  }

  @objc func nextButtonPressed(_ sender: Any) {
    // Override this function.
  }

  @objc func skipButtonPressed(_ sender: Any) {
    viewModel.finishOnboardingFlow()
  }

}
