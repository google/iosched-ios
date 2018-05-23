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
import UIKit
import MaterialComponents
import AlamofireImage

class UserAccountInfoViewController: UIViewController, UIScrollViewDelegate {

  let viewModel: UserAccountInfoViewModel

  private enum ColorConstants {
    static let email = UIColor(red: 95 / 255, green: 99 / 255, blue: 104 / 255, alpha: 1)
    static let name = UIColor(red: 60 / 255, green: 64 / 255, blue: 67 / 255, alpha: 1)
    static let actionButton = UIColor(hex: "4668fd")
  }

  private enum LayoutConstants {
    static let standardSpacing: CGFloat = 16
    static let horizontalMargin: CGFloat = 20
    static let thumbnailWidth: CGFloat = 72
  }

  private lazy var actionButton: MDCButton = self.setupActionButton()
  private lazy var emailLabel: UILabel = self.setupEmailLabel()
  private lazy var messageLabel: UILabel = self.setupMessageLabel()
  private lazy var manageAccountView = self.setupManageAccountView()
  private lazy var nameLabel: UILabel = self.setupNameLabel()
  private lazy var thumbnailImageView: UIImageView = self.setupThumbnailImageView()
  private lazy var scrollView: UIScrollView = self.setupScrollView()
  private lazy var stackView: UIStackView = self.setupMainStackView()
  private lazy var profileStackView: UIStackView = self.setupProfileStackView()
  private lazy var nameEmailStackView: UIStackView = self.setupNameEmailStackView()
  private lazy var signOutButton: UIBarButtonItem = self.setupSignOutButton()
  private lazy var settingsView: UserAccountSettingsView = self.setupSettingsView()
  private lazy var builtWithView: UserAccountSettingsBuiltWithView = self.setupBuiltWithView()
  private lazy var buildInfoView: UserAccountSettingsInfoView = self.setupBuildInfoview()

  let settingsViewModel: SettingsViewModel

  init(viewModel: UserAccountInfoViewModel, settingsViewModel: SettingsViewModel) {
    self.viewModel = viewModel
    self.settingsViewModel = settingsViewModel

    super.init(nibName: nil, bundle: nil)
    super.modalPresentationStyle = .fullScreen
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addChild(appBar)
    view.addSubview(appBar.view)
    appBar.didMove(toParent: self)
    appBar.headerView.trackingScrollView = scrollView
    scrollView.delegate = self
    title = NSLocalizedString("Settings", comment: "Title of the Settings screen.")

    navigationItem.rightBarButtonItem = signOutButton
    setupViews()

    view.sendSubviewToBack(scrollView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateFromViewModel()
    viewModel.signInStateChangeCallback = { [unowned self] _ in
      self.updateFromViewModel()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewModel.signInStateChangeCallback = nil
  }

  private func setupNameLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .title)
    label.enableAdjustFontForContentSizeCategory()
    label.textColor = ColorConstants.name
    label.numberOfLines = 0
    return label
  }

  private func setupEmailLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .subheadline)
    label.enableAdjustFontForContentSizeCategory()
    label.textColor = ColorConstants.email
    label.numberOfLines = 0
    return label
  }

  private func setupThumbnailImageView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 19
    imageView.clipsToBounds = true
    imageView.image = UIImage(named: Constants.profilePlaceholderName)
    return imageView
  }

  private func setupMessageLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)
    label.enableAdjustFontForContentSizeCategory()
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
  }

  private func setupManageAccountView() -> ManageYourGoogleAccountButtonContainer {
    let view = ManageYourGoogleAccountButtonContainer()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  private func setupSettingsView() -> UserAccountSettingsView {
    let view = UserAccountSettingsView(settingsViewModel)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  private func setupBuiltWithView() -> UserAccountSettingsBuiltWithView {
    let view = UserAccountSettingsBuiltWithView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleMDCTap)))
    return view
  }

  private func setupBuildInfoview() -> UserAccountSettingsInfoView {
    let view = UserAccountSettingsInfoView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.delegate = self
    return view
  }

  lazy private var appBar: MDCAppBarViewController = {
    let appBar = MDCAppBarViewController()

    let headerView = appBar.headerView
    headerView.backgroundColor = UIColor.white
    headerView.minimumHeight = topLayoutGuide.length + 104
    headerView.maximumHeight = topLayoutGuide.length + 104

    appBar.navigationBar.tintColor = UIColor(hex: "#202124")
    appBar.navigationBar.uppercasesButtonTitles = false
    appBar.navigationBar.titleViewLayoutBehavior = .fill

    var attributes: [NSAttributedString.Key: Any] =
      [NSAttributedString.Key.foregroundColor: UIColor(hex: "#202124")]
    let font = UIFont(name: "Product Sans", size: 24)
    if let font = font {
      attributes[NSAttributedString.Key.font] = font
    }
    appBar.navigationBar.titleTextAttributes = attributes
    appBar.navigationBar.titleViewLayoutBehavior = .center
    appBar.inferTopSafeAreaInsetFromViewController = true

    return appBar
  }()

  private func setupScrollView() -> UIScrollView {
    let scrollView = UIScrollView ()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }

  private func setupMainStackView() -> UIStackView {
    let stackView = UIStackView()
    stackView.alignment = .center
    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }

  private func setupProfileStackView() -> UIStackView {
    let stackView = UIStackView()
    stackView.alignment = .center
    stackView.axis = .vertical
    stackView.spacing = LayoutConstants.standardSpacing
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.layoutMargins = UIEdgeInsets(top: 0,
                                           left: LayoutConstants.horizontalMargin,
                                           bottom: 0,
                                           right: LayoutConstants.horizontalMargin)
    stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return stackView
  }

  private func setupNameEmailStackView() -> UIStackView {
    let stackView = self.setupProfileStackView()
    stackView.spacing = 1
    return stackView
  }

  private func setupActionButton() -> MDCButton {
    let button = MDCRaisedButton()
    button.isUppercaseTitle = false
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setBackgroundColor(ColorConstants.actionButton, for: .normal)
    button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    button.titleLabel?.enableAdjustFontForContentSizeCategory()
    return button
  }

  private func setupSignOutButton() -> UIBarButtonItem {
    // This button value gets overriden when the view model updates.
    let button = UIBarButtonItem(title: NSLocalizedString("Sign out", comment: "Sign Out button"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(buttonTapped))
    button.setTitleTextAttributes([.foregroundColor: ColorConstants.actionButton], for: .normal)
    return button
  }

  private enum MDCConstants {
    static let materialComponentsURL = "https://material.io/components"
  }

  @objc private func handleMDCTap() {
    if let url = URL(string: MDCConstants.materialComponentsURL) {
      if #available(iOS 10.0, *) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } else {
        UIApplication.shared.openURL(url)
      }
    }
  }

  private func setupViews() {
    view.backgroundColor = .white

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    stackView.addArrangedSubview(profileStackView)

    nameEmailStackView.addArrangedSubview(nameLabel)
    nameEmailStackView.addArrangedSubview(emailLabel)

    profileStackView.addArrangedSubview(thumbnailImageView)
    profileStackView.addArrangedSubview(nameEmailStackView)
    profileStackView.addArrangedSubview(manageAccountView)
    profileStackView.addArrangedSubview(messageLabel)
    profileStackView.addArrangedSubview(actionButton)

    stackView.addArrangedSubview(settingsView)
    stackView.addArrangedSubview(builtWithView)
    stackView.addArrangedSubview(buildInfoView)
    stackView.spacing = 16

    // Thumbnail view constraints.
    var constraints = [
      thumbnailImageView.heightAnchor.constraint(equalToConstant: LayoutConstants.thumbnailWidth),
      thumbnailImageView.widthAnchor.constraint(equalToConstant: LayoutConstants.thumbnailWidth)
    ]

    // Settings and built with view
    constraints += [settingsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                    builtWithView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                    buildInfoView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)]

    // main scroll view
    constraints += [scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                    scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 1.0),
                    scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 1.0),
                    scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1.0)]

    // stack view
    constraints += [stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                    stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                    stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)]

    NSLayoutConstraint.activate(constraints)
  }

  private enum Constants {
    static let profilePlaceholderName = "ic_profile_placeholder"
    static let profileImageWidth: CGFloat = 72
    static let profileImageHeight: CGFloat = 72
    static let profileImageRadius = profileImageHeight / 2.0
  }

  func attributedText(for text: String) -> NSAttributedString {
    let attributedText = InfoDetail.attributedText(detail: text)
    return attributedText ?? NSAttributedString(string: "")
  }

  private enum AttributedStringConstants {
    static let css = "h1 { font-weight:normal; font-size: 32px; font-family: Product Sans } ul { margin-top: 0px; }"
    static let linkColor = "#536DFE"
    static let paragraphStyle: NSParagraphStyle = { () -> NSParagraphStyle in
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineHeightMultiple = 18 / 14 // 24pt line
      paragraphStyle.paragraphSpacing = 0
      return paragraphStyle
    }()
    static let textColor = "#747474"
    static let textSize: CGFloat = 14.0
  }

  private func updateFromViewModel() {
    nameLabel.text = viewModel.userNameText
    emailLabel.text = viewModel.userEmailText

    manageAccountView.isEnabled = viewModel.isSignedIn

    if let messageText = viewModel.messageText {
      messageLabel.attributedText = attributedText(for: messageText)
      messageLabel.textAlignment = .center
      messageLabel.sizeToFit()
    }

    actionButton.setTitle(viewModel.actionButtonText, for: .normal)

    actionButton.isHidden = viewModel.isSignedIn
    signOutButton.isEnabled = viewModel.isSignedIn
    let placeHolder = UIImage(named: Constants.profilePlaceholderName)

    guard let thumbnailURL = viewModel.thumbnailURL,
      let url = URL(string: thumbnailURL) else {
        thumbnailImageView.image = placeHolder
        return
    }

    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
      size: CGSize(width: Constants.profileImageWidth,
                   height: Constants.profileImageHeight),
      radius: Constants.profileImageRadius)

    thumbnailImageView.af_setImage(withURL: url,
                                   placeholderImage: placeHolder,
                                   filter: filter,
                                   imageTransition: .crossDissolve(0.2))
  }

  @objc func close(sender: UIBarButtonItem) {
    if let navController = self.navigationController {
      navController.popViewController(animated: true)
    } else {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @objc func buttonTapped() {
    if viewModel.isSignedIn {
      viewModel.signOut()
    } else {
      viewModel.presentSignIn()
    }
  }

  // MARK: UIScrollViewDelegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView == appBar.headerView.trackingScrollView {
      appBar.headerView.trackingScrollDidScroll()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if scrollView == appBar.headerView.trackingScrollView {
      appBar.headerView.trackingScrollDidEndDecelerating()
    }
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                willDecelerate decelerate: Bool) {
    let headerView = appBar.headerView
    if scrollView == headerView.trackingScrollView {
      headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
    }
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                 withVelocity velocity: CGPoint,
                                 targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let headerView = appBar.headerView
    if scrollView == headerView.trackingScrollView {
      headerView.trackingScrollWillEndDragging(withVelocity: velocity,
                                               targetContentOffset: targetContentOffset)
    }
  }

}

// MARK: - UserAccountSettingsInfoViewDelegate

extension UserAccountInfoViewController: UserAccountSettingsInfoViewDelegate {
  func didTapOpenSourceLicenses(view: UIView) {
    let controller = AcknowledgementsViewController()
    let navController = UINavigationController(rootViewController: controller)
    navController.modalPresentationStyle = .popover
    navController.popoverPresentationController?.sourceView = view
    self.present(navController, animated: true, completion: nil)
  }

}
