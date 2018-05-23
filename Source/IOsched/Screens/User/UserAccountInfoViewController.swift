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
import DTCoreText
import GoogleSignIn

class UserAccountInfoViewController: UIViewController {

  var viewModel: UserAccountInfoViewModel?

  private enum ColorConstants {
    static let email = UIColor(hex: "#787878").withAlphaComponent(0.7)
    static let name = UIColor(hex: "#747474").withAlphaComponent(0.7)
    static let actionButton = UIColor(hex: "4668fd")
  }

  private enum LayoutConstants {
    static let standardSpacing: CGFloat = 16
    static let horizontalMargin: CGFloat = 20
    static let thumbnailWidth: CGFloat = 72
  }

  private lazy var actionButton: MDCButton = self.setupActionButton()
  private lazy var emailLabel: UILabel = self.setupEmailLabel()
  private lazy var navBar: MDCNavigationBar = self.setupNavBar()
  private lazy var messageLabel: UILabel = self.setupMessageLabel()
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
    setupViews()
    updateFromViewModel()
    view.setNeedsLayout()
  }

  private func setupNameLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = MDCTypography.titleFont()
    label.textColor = ColorConstants.name
    label.numberOfLines = 0
    return label
  }

  private func setupEmailLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = MDCTypography.subheadFont()
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
    label.font = MDCTypography.body1Font()
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
  }

  private func setupSettingsView() -> UserAccountSettingsView {
    let view = UserAccountSettingsView(settingsViewModel)
    view.translatesAutoresizingMaskIntoConstraints = false;
    return view
  }

  private func setupBuiltWithView() -> UserAccountSettingsBuiltWithView {
    let view = UserAccountSettingsBuiltWithView()
    view.translatesAutoresizingMaskIntoConstraints = false;
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleMDCTap)))
    return view
  }

  private func setupBuildInfoview() -> UserAccountSettingsInfoView {
    let view = UserAccountSettingsInfoView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.delegate = self
    return view
  }

  private func setupNavBar() -> MDCNavigationBar {
    let navBar = MDCNavigationBar()
    navBar.observe(navigationItem)

    let closeButton = UIBarButtonItem(image: UIImage(named: "close.png"), style: .plain, target:self, action:#selector(close(sender:)))
    self.navigationItem.leftBarButtonItem = closeButton
    self.navigationItem.rightBarButtonItem = signOutButton

    navBar.translatesAutoresizingMaskIntoConstraints = false
    return navBar;
  }

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
    stackView.layoutMargins = UIEdgeInsetsMake(0,
                                               LayoutConstants.horizontalMargin,
                                               0,
                                               LayoutConstants.horizontalMargin)
    stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return stackView
  }

  private func setupNameEmailStackView() -> UIStackView {
    let stackView = self.setupProfileStackView()
    stackView.spacing = 1;
    return stackView
  }

  private func setupActionButton() -> MDCButton {
    let button = MDCRaisedButton()
    button.isUppercaseTitle = false
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setBackgroundColor(ColorConstants.actionButton, for: .normal)
    button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    return button
  }

  private func setupSignOutButton() -> UIBarButtonItem {
    // This button value gets overriden when the view model updates.
    let button = UIBarButtonItem(title: NSLocalizedString("Sign out", comment: "Sign Out button"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(buttonTapped))
    button.setTitleTextAttributes([.foregroundColor:ColorConstants.actionButton], for: .normal)
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

    view.addSubview(navBar)
    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    stackView.addArrangedSubview(profileStackView)

    nameEmailStackView.addArrangedSubview(nameLabel)
    nameEmailStackView.addArrangedSubview(emailLabel)

    profileStackView.addArrangedSubview(thumbnailImageView)
    profileStackView.addArrangedSubview(nameEmailStackView)
    profileStackView.addArrangedSubview(messageLabel)
    profileStackView.addArrangedSubview(actionButton)

    stackView.addArrangedSubview(settingsView)
    stackView.addArrangedSubview(builtWithView)
    stackView.addArrangedSubview(buildInfoView)

    // Thumbnail view constraints.
    var constraints = [
      thumbnailImageView.heightAnchor.constraint(equalToConstant: LayoutConstants.thumbnailWidth),
      thumbnailImageView.widthAnchor.constraint(equalToConstant:LayoutConstants.thumbnailWidth)
    ]

    // Navbar
    if #available(iOS 11, *) {
      constraints += [navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)]
    } else {
      constraints += [navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)]
    }

    constraints += [
      navBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
      navBar.heightAnchor.constraint(equalToConstant: navBar.intrinsicContentSize.height)
    ]

    // Settings and built with view
    constraints += [settingsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                    builtWithView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                    buildInfoView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)]


    // main scroll view
    constraints += [scrollView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
                    scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 1.0),
                    scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 1.0),
                    scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1.0)]

    // stack view
    constraints += [stackView.leadingAnchor.constraint(equalTo:scrollView.leadingAnchor),
                    stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                    stackView.topAnchor.constraint(equalTo:scrollView.topAnchor),
                    stackView.widthAnchor.constraint(equalTo:scrollView.widthAnchor)]

    NSLayoutConstraint.activate(constraints)
  }

  private enum Constants {
    static let profilePlaceholderName = "ic_profile_placeholder"
    static let profileImageWidth: CGFloat = 72
    static let profileImageHeight: CGFloat = 72
    static let profileImageRadius = profileImageHeight / 2.0
  }

  func attributedText(for text: String) -> NSAttributedString {
    let data = text.data(using: .utf8)
    let attributedText = NSAttributedString(htmlData: data,
                                            options: attributedStringOptions,
                                            documentAttributes: nil)!
    return attributedText
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
    static let options = [
      DTDefaultFontName: UIFont.systemFont(ofSize: AttributedStringConstants.textSize).fontName,
      DTDefaultFontFamily: UIFont.systemFont(ofSize: UIFont.systemFontSize).familyName,
      DTDefaultFontSize: UIFont.systemFontSize,
      DTUseiOS6Attributes: true,
      DTDefaultTextColor: UIColor(hex: AttributedStringConstants.textColor),
      DTDefaultLinkColor: UIColor(hex: AttributedStringConstants.linkColor),
      DTDefaultLineHeightMultiplier: AttributedStringConstants.paragraphStyle.lineHeightMultiple,
      DTDefaultStyleSheet: DTCSSStylesheet(styleBlock: AttributedStringConstants.css)
      ] as [String : Any]
    static let textColor = "#747474"
    static let textSize: CGFloat = 14.0
  }

  var attributedStringOptions: [String: Any] {
    return AttributedStringConstants.options
  }

  private func updateFromViewModel() {
    if let viewModel = viewModel {
      nameLabel.text = viewModel.userNameText
      emailLabel.text = viewModel.userEmailText

      if let messageText = viewModel.messageText {
        messageLabel.attributedText = attributedText(for: messageText)
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
      }

      actionButton.setTitle(viewModel.actionButtonText, for: .normal)

      actionButton.isHidden = viewModel.isSignedIn
      signOutButton.isEnabled = viewModel.isSignedIn

      guard let thumbnailUrl = viewModel.thumbnailUrl else { return }
      guard let url = URL(string: thumbnailUrl) else { return }

      let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
        size: CGSize(width: Constants.profileImageWidth,
                     height: Constants.profileImageHeight),
        radius: Constants.profileImageRadius)
      let placeHolder = UIImage(named: Constants.profilePlaceholderName)

      thumbnailImageView.af_setImage(withURL: url, placeholderImage: placeHolder, filter: filter, imageTransition: .crossDissolve(0.2))
    }
  }

  @objc func close(sender: UIBarButtonItem) {
    self.dismiss(animated: true, completion: nil)
  }

  @objc func buttonTapped() {
    guard let viewModel = viewModel else { return }

    self.dismiss(animated: true) {
      if viewModel.isSignedIn {
        viewModel.signOut()
      }
      else {
        self.signIn()
      }
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

extension UserAccountInfoViewController {

  func signIn() {
    SignIn.sharedInstance.signIn { (user, error) in
      guard error == nil else {
        self.viewModel?.signInFailed(withError: error!)
        return
      }

      if let user = user {
        self.viewModel?.signInSuccessful(user: user)
        self.dismiss(animated: true)
      }
    }
  }
}
