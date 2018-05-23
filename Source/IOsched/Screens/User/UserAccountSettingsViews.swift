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

import MaterialComponents

class UserAccountSettingsView: UIView {

  // This is nullable and gross because we don't control cell initialization
  // (the collection view does), but we'd like to inject this anyway.
  var settingsViewModel: SettingsViewModel?

  private struct Constants {

    static let labelTextColor = UIColor(red: 42 / 255, green: 42 / 255, blue: 42 / 255, alpha: 1)
    static let switchOnTintColor = UIColor(red: 82 / 255, green: 108 / 255, blue: 254 / 255, alpha: 1)
    static let switchTintColor = UIColor(red: 189 / 255, green: 189 / 255, blue: 189 / 255, alpha: 1)

    static let analyticsText = NSLocalizedString("Send anonymous usage statistics", comment: "Short description of the analytics setting. Text should not be too long or it will display incorrectly")
    static let eventTimesText = NSLocalizedString("Event times in Pacific time zone", comment: "Short description of the event times in pacific time setting. Text should not be too long or it will display incorrectly")
    static let notificationsText = NSLocalizedString("Enable notifications", comment: "Short description of the notifications setting. Text should not be too long or it will display incorrectly")

    static let labelFont = { () -> UIFont in return UIFont.preferredFont(forTextStyle: .subheadline) }

    // duplicated constraint code to calculate content size
    static let topInset: CGFloat = 20
    static let interItemVerticalSpacing: CGFloat = 30
    static let bottomInset: CGFloat = 20

  }

  let eventTimesLabel = UILabel()
  let notificationsLabel = UILabel()
  let analyticsLabel = UILabel()

  let eventTimesSwitch = UISwitch()
  let notificationsSwitch = UISwitch()
  let analyticsSwitch = UISwitch()

  init(_ viewModel: SettingsViewModel) {
    super.init(frame: CGRect.zero)
    self.settingsViewModel = viewModel

    [eventTimesLabel, notificationsLabel, analyticsLabel].forEach {
      self.self.addSubview($0)
    }
    [eventTimesSwitch, notificationsSwitch, analyticsSwitch].forEach {
      self.self.addSubview($0)
    }

    setupLabels()
    setupSwitches()
    setupConstraints()

    backgroundColor = UIColor(hex: 0xf8f9fa)

    eventTimesSwitch.isOn = viewModel.shouldDisplayEventsInPDT
    notificationsSwitch.isOn = viewModel.isNotificationsEnabled
    analyticsSwitch.isOn = viewModel.isAnalyticsEnabled
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: UserAccountSettingsView.heightForContents())
  }

  static func heightForContents() -> CGFloat {
    let textHeights = [
      Constants.eventTimesText,
      Constants.notificationsText,
      Constants.analyticsText
    ].reduce(0 as CGFloat) { (result, string) -> CGFloat in
      return result + string.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                       height: CGFloat.greatestFiniteMagnitude),
                                          options: [.usesLineFragmentOrigin],
                                          attributes: [NSAttributedString.Key.font: Constants.labelFont()],
                                          context: nil).size.height
    }

    return textHeights + Constants.topInset + Constants.bottomInset
        + Constants.interItemVerticalSpacing * 2
  }

  func setupLabels() {
    [eventTimesLabel, notificationsLabel, analyticsLabel].forEach { label in
      label.translatesAutoresizingMaskIntoConstraints = false
      label.font = Constants.labelFont()
      label.numberOfLines = 1
      label.textColor = Constants.labelTextColor

      // The accessibility label is on the switch control directly so VoiceOver reads them
      // as one unit.
      label.isAccessibilityElement = false
    }
    eventTimesLabel.text = Constants.eventTimesText
    notificationsLabel.text = Constants.notificationsText
    analyticsLabel.text = Constants.analyticsText
  }

  func setupSwitches() {
    [eventTimesSwitch, notificationsSwitch, analyticsSwitch].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.onTintColor = Constants.switchOnTintColor
      $0.addTarget(self, action: #selector(didTapSwitch(_:)), for: .touchUpInside)
    }

    eventTimesSwitch.accessibilityLabel = Constants.eventTimesText
    notificationsSwitch.accessibilityLabel = Constants.notificationsText
    analyticsSwitch.accessibilityLabel = Constants.analyticsText
  }

  func setupConstraints() {
    var constraints: [NSLayoutConstraint] = []

    // event times label top
    constraints.append(NSLayoutConstraint(item: eventTimesLabel,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: Constants.topInset))
    // event times label left
    constraints.append(NSLayoutConstraint(item: eventTimesLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 16))
    // notifications label top
    constraints.append(NSLayoutConstraint(item: notificationsLabel,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: eventTimesLabel,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: Constants.interItemVerticalSpacing))
    // notifications label left
    constraints.append(NSLayoutConstraint(item: notificationsLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 16))
    // analytics label top
    constraints.append(NSLayoutConstraint(item: analyticsLabel,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: notificationsLabel,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: Constants.interItemVerticalSpacing))
    // analytics label left
    constraints.append(NSLayoutConstraint(item: analyticsLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 16))
    // event times switch centerY
    constraints.append(NSLayoutConstraint(item: eventTimesSwitch,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: eventTimesLabel,
                                          attribute: .centerY,
                                          multiplier: 1,
                                          constant: 0))
    // event times switch right
    constraints.append(NSLayoutConstraint(item: eventTimesSwitch,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -16))
    // notifications switch centerY
    constraints.append(NSLayoutConstraint(item: notificationsSwitch,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: notificationsLabel,
                                          attribute: .centerY,
                                          multiplier: 1,
                                          constant: 0))
    // notifications switch right
    constraints.append(NSLayoutConstraint(item: notificationsSwitch,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -16))
    // analytics switch centerY
    constraints.append(NSLayoutConstraint(item: analyticsSwitch,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: analyticsLabel,
                                          attribute: .centerY,
                                          multiplier: 1,
                                          constant: 0))
    // analytics switch right
    constraints.append(NSLayoutConstraint(item: analyticsSwitch,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -16))

    self.addConstraints(constraints)
  }

  @objc func didTapSwitch(_ anySender: Any) {
    guard let sender = anySender as? UISwitch else { return }
    guard let viewModel = settingsViewModel else { return }
    switch sender {

    case eventTimesSwitch:
      viewModel.toggleEventsInPacificTime()

    case notificationsSwitch:
      viewModel.toggleNotificationsEnabled()

      // App doesn't have the permissions to display notifications, even though we can
      // still receive them through FCM. Deep link to Settings.app here so user can change
      // permissions easily.
      if !viewModel.hasNotificationPermissions && viewModel.isNotificationsEnabled {
        viewModel.presentSettingsDeepLinkAlert { _ in
          viewModel.isNotificationsEnabled = false
          self.notificationsSwitch.setOn(false, animated: true)
        }
      }

    case analyticsSwitch:
      viewModel.toggleAnalyticsEnabled()

    case _:
      return
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let font = Constants.labelFont()
    if font.pointSize != analyticsLabel.font.pointSize {
      eventTimesLabel.font = font
      notificationsLabel.font = font
      analyticsLabel.font = font
    }

    notificationsSwitch.isOn = settingsViewModel?.isNotificationsEnabled ?? false
  }

  @available(*, unavailable)
  required init(coder aDecoder: NSCoder) {
    fatalError("NSCoding not supported for cell of type \(WifiInfoCollectionViewCell.self)")
  }

}

class UserAccountSettingsBuiltWithView: UIView {

  private struct Constants {
    static let builtText = "Built with"
    static let materialComponentsText = "Material Components"
  }

  let builtWith: UILabel = {
    let builtWith = UILabel()
    builtWith.translatesAutoresizingMaskIntoConstraints = false
    builtWith.text = Constants.builtText
    builtWith.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .subheadline)
    builtWith.enableAdjustFontForContentSizeCategory()
    builtWith.textColor = UIColor(white: 0, alpha: MDCTypography.subheadFontOpacity())
    builtWith.textAlignment = .left
    return builtWith
  }()

  let logo: MDCLogo = {
    let logo = MDCLogo()
    logo.translatesAutoresizingMaskIntoConstraints = false
    return logo
  }()

  let materialComponents: UILabel = {
    let materialComponents = UILabel()
    materialComponents.translatesAutoresizingMaskIntoConstraints = false
    materialComponents.text = Constants.materialComponentsText
    materialComponents.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .headline)
    materialComponents.enableAdjustFontForContentSizeCategory()
    materialComponents.textColor = UIColor(white: 0, alpha: MDCTypography.headlineFontOpacity())
    materialComponents.textAlignment = .left
    materialComponents.adjustsFontSizeToFitWidth = true
    return materialComponents
  }()

  class MDCLogo: UIView {

    override init(frame: CGRect) {
      super.init(frame: frame)
      backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
      super.draw(rect)

      drawLogo(frame: rect)
    }

    func drawLogo(frame: CGRect) {
      // Generated code. Do not alter by hand.

      // This non-generic function dramatically improves compilation times of complex expressions.
      func fastFloor(_ x: CGFloat) -> CGFloat { return floor(x) }

      let black = UIColor(red: 0.129, green: 0.129, blue: 0.129, alpha: 1.000)
      let lightGreen = UIColor(red: 0.698, green: 1.000, blue: 0.349, alpha: 1.000)
      let mediumGreen = UIColor(red: 0.000, green: 0.902, blue: 0.463, alpha: 1.000)

      let mDCGroup: CGRect = CGRect(x: frame.minX + 2, y: frame.minY + 2, width: fastFloor((frame.width - 2) * 0.97959 + 0.5), height: fastFloor((frame.height - 2) * 0.97959 + 0.5))

      let bezierPath = UIBezierPath()
      bezierPath.move(to: CGPoint(x: mDCGroup.minX + 0.00000 * mDCGroup.width, y: mDCGroup.minY + 0.66667 * mDCGroup.height))
      bezierPath.addLine(to: CGPoint(x: mDCGroup.minX + 0.33333 * mDCGroup.width, y: mDCGroup.minY + 0.66667 * mDCGroup.height))
      bezierPath.addLine(to: CGPoint(x: mDCGroup.minX + 0.66667 * mDCGroup.width, y: mDCGroup.minY + 0.33333 * mDCGroup.height))
      bezierPath.addLine(to: CGPoint(x: mDCGroup.minX + 0.66667 * mDCGroup.width, y: mDCGroup.minY + 0.00000 * mDCGroup.height))
      bezierPath.addLine(to: CGPoint(x: mDCGroup.minX + 0.00000 * mDCGroup.width, y: mDCGroup.minY + 0.00000 * mDCGroup.height))
      bezierPath.addLine(to: CGPoint(x: mDCGroup.minX + 0.00000 * mDCGroup.width, y: mDCGroup.minY + 0.66667 * mDCGroup.height))
      bezierPath.close()
      black.setFill()
      bezierPath.fill()

      let ovalPath = UIBezierPath(ovalIn: CGRect(x: mDCGroup.minX + fastFloor(mDCGroup.width * 0.33333 + 0.5), y: mDCGroup.minY + fastFloor(mDCGroup.height * 0.33333 + 0.5), width: fastFloor(mDCGroup.width * 1.00000 + 0.5) - fastFloor(mDCGroup.width * 0.33333 + 0.5), height: fastFloor(mDCGroup.height * 1.00000 + 0.5) - fastFloor(mDCGroup.height * 0.33333 + 0.5)))
      lightGreen.setFill()
      ovalPath.fill()

      let bezier2Path = UIBezierPath()
      bezier2Path.move(to: CGPoint(x: mDCGroup.minX + 0.66667 * mDCGroup.width, y: mDCGroup.minY + 0.33333 * mDCGroup.height))
      bezier2Path.addLine(to: CGPoint(x: mDCGroup.minX + 0.66667 * mDCGroup.width, y: mDCGroup.minY + 0.33333 * mDCGroup.height))
      bezier2Path.addCurve(to: CGPoint(x: mDCGroup.minX + 0.33333 * mDCGroup.width, y: mDCGroup.minY + 0.66667 * mDCGroup.height), controlPoint1: CGPoint(x: mDCGroup.minX + 0.48257 * mDCGroup.width, y: mDCGroup.minY + 0.33333 * mDCGroup.height), controlPoint2: CGPoint(x: mDCGroup.minX + 0.33333 * mDCGroup.width, y: mDCGroup.minY + 0.48257 * mDCGroup.height))
      bezier2Path.addLine(to: CGPoint(x: mDCGroup.minX + 0.66667 * mDCGroup.width, y: mDCGroup.minY + 0.66667 * mDCGroup.height))
      bezier2Path.addLine(to: CGPoint(x: mDCGroup.minX + 0.66667 * mDCGroup.width, y: mDCGroup.minY + 0.33333 * mDCGroup.height))
      bezier2Path.close()
      mediumGreen.setFill()
      bezier2Path.fill()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    setupLayout()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupLayout() {
    self.addSubview(logo)

    self.addSubview(builtWith)
    self.addSubview(materialComponents)

    NSLayoutConstraint(item: logo,
                       attribute: .width,
                       relatedBy: .equal,
                       toItem: logo,
                       attribute: .height,
                       multiplier: 1,
                       constant: 0).isActive = true
    NSLayoutConstraint(item: logo,
                       attribute: .height,
                       relatedBy: .equal,
                       toItem: nil,
                       attribute: .notAnAttribute,
                       multiplier: 1,
                       constant: 60).isActive = true
    NSLayoutConstraint(item: logo,
                       attribute: .centerY,
                       relatedBy: .equal,
                       toItem: logo.superview,
                       attribute: .centerY,
                       multiplier: 1,
                       constant: 0).isActive = true
    NSLayoutConstraint(item: logo,
                       attribute: .leading,
                       relatedBy: .equal,
                       toItem: logo.superview,
                       attribute: .leading,
                       multiplier: 1,
                       constant: 20).isActive = true
    NSLayoutConstraint(item: builtWith,
                       attribute: .leading,
                       relatedBy: .equal,
                       toItem: logo,
                       attribute: .trailing,
                       multiplier: 1,
                       constant: 15).isActive = true
    NSLayoutConstraint(item: materialComponents,
                       attribute: .trailing,
                       relatedBy: .lessThanOrEqual,
                       toItem: materialComponents.superview,
                       attribute: .trailing,
                       multiplier: 1,
                       constant: -16).isActive = true
    NSLayoutConstraint(item: materialComponents,
                       attribute: .leading,
                       relatedBy: .equal,
                       toItem: logo,
                       attribute: .trailing,
                       multiplier: 1,
                       constant: 15).isActive = true
    NSLayoutConstraint(item: builtWith,
                       attribute: .top,
                       relatedBy: .equal,
                       toItem: builtWith.superview,
                       attribute: .top,
                       multiplier: 1,
                       constant: 24).isActive = true
    NSLayoutConstraint(item: materialComponents,
                       attribute: .top,
                       relatedBy: .equal,
                       toItem: builtWith,
                       attribute: .bottom,
                       multiplier: 1,
                       constant: 0).isActive = true
  }

  static func heightForContents() -> CGFloat {
    return 100
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: UserAccountSettingsBuiltWithView.heightForContents())
  }
}

protocol UserAccountSettingsInfoViewDelegate: NSObjectProtocol {
  func didTapOpenSourceLicenses(view: UIView)
}

class UserAccountSettingsInfoView: UIView {

  weak var delegate: UserAccountSettingsInfoViewDelegate?

  fileprivate struct Constants {
    static let contents = NSLocalizedString("<p><a href='https://www.google.com/policies/terms/'>Terms of Service</a><br /><a href='https://www.google.com/policies/privacy/'>Privacy Policy</a><br /><a href='\(Constants.acknowledgementsURL.absoluteString)'>Open Source Licenses</a></p><p>Version \(Constants.versionString), Build \(Constants.buildString)<p/>", comment: "Localized HTML listing Terms of Service, Open Source Licenses, and version number")

    static let font = { () -> UIFont in return UIFont.preferredFont(forTextStyle: .body) }

    // We don't have an official url scheme, but the app knows how to open this url.
    // This exists so we can insert these urls into attributed strings in our app
    // and link to them without having to make special method calls.
    static let acknowledgementsURL: URL = URL(string: "iosched://acknowledgements")!

    static let versionString: String = { () -> String in
      // Failing to fetch the version from the info plist is a programmer error (my error) and
      // should never happen, but doesn't seem like big enough an issue warrant a fatalError.
      let unknownVersion = "999.0.0"

      let version = Bundle.main.url(forResource: "Info", withExtension: "plist").flatMap {
          return NSDictionary(contentsOf: $0) as? [String: Any]
        }
        .flatMap {
          return $0["CFBundleShortVersionString"] as? String
        } ?? unknownVersion

      return version
    }()

    static let buildString: String = { () -> String in
      // Failing to fetch the version from the info plist is a programmer error (my error) and
      // should never happen, but doesn't seem like big enough an issue warrant a fatalError.
      let unknownBuild = "42"

      let build = Bundle.main.url(forResource: "Info", withExtension: "plist").flatMap {
        return NSDictionary(contentsOf: $0) as? [String: Any]
        }
        .flatMap {
          return $0["CFBundleVersion"] as? String
        } ?? unknownBuild

      return build
    }()

    static let linkColor = UIColor(red: 61 / 255, green: 90 / 255, blue: 254 / 255, alpha: 1)
  }

  let textView = UITextView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.addSubview(textView)
    setupTextView()
    setupConstraints()
  }

  private func setupTextView() {
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isScrollEnabled = false
    textView.isEditable = false

    textView.attributedText = InfoDetailView.attributedText(forDetailText: Constants.contents)
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainerInset = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
    textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: Constants.linkColor]

    textView.font = Constants.font()
    textView.delegate = self
  }

  private func setupConstraints() {
    var constraints: [NSLayoutConstraint] = []

    // text view top
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: 0))
    // text view left
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 0))
    // text view right
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: 0))
    // text view bottom
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .bottom,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: 0))

    self.addConstraints(constraints)
  }

  static func heightForContents(maxWidth: CGFloat) -> CGFloat {
    return InfoDetailView.height(forDetailText: Constants.contents, maxWidth: maxWidth)
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric,
                  height: UserAccountSettingsInfoView.heightForContents(
                    maxWidth: min(superview!.frame.width, superview!.frame.height)))
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Support dynamic type
    let font = Constants.font()
    if font.pointSize != textView.font?.pointSize {
      textView.font = font
    }
  }

  @available(*, unavailable)
  required init(coder aDecoder: NSCoder) {
    fatalError("NSCoding not supported for cell of type \(WifiInfoCollectionViewCell.self)")
  }

}

extension UserAccountSettingsInfoView: UITextViewDelegate {

  @available(iOS 10.0, *)
  func textView(_ textView: UITextView,
                shouldInteractWith url: URL,
                in characterRange: NSRange,
                interaction: UITextItemInteraction) -> Bool {
    if url == Constants.acknowledgementsURL {
      if let delegate = delegate {
        delegate.didTapOpenSourceLicenses(view: textView)
      }
      return false
    }

    return true
  }

  @available(iOS, deprecated: 10.0)
  func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
    if url == Constants.acknowledgementsURL {
      if let delegate = delegate {
        delegate.didTapOpenSourceLicenses(view: textView)
      }
      return false
    }

    return true
  }

}

class ManageYourGoogleAccountButtonContainer: UIView {

  var isEnabled: Bool {
    get {
      return manageYourAccountButton.isEnabled
    }
    set {
      manageYourAccountButton.isEnabled = newValue
      manageYourAccountButton.isHidden = !newValue
      removeConstraints(constraints)
      if newValue {
        heightConstraint.isActive = false
        setupConstraints()
      } else {
        heightConstraint.isActive = true
      }
      setNeedsLayout()
    }
  }

  private let manageYourAccountButton: MDCButton = {
    let button = MDCFlatButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    let font = UIFont.preferredFont(forTextStyle: .caption1)
    button.setTitleFont(font, for: .normal)
    let title = NSLocalizedString("Manage your Google account",
                                  comment: "Button text. Tapping the button navigates users to an account management screen.")
    button.setTitle(title, for: .normal)
    let titleColor = UIColor(red: 32 / 255, green: 33 / 255, blue: 36 / 255, alpha: 1)
    button.setTitleColor(titleColor, for: .normal)
    button.titleLabel?.numberOfLines = 0
    button.addTarget(self, action: #selector(manageAccountButtonTapped(_:)), for: .touchUpInside)
    button.addTarget(self, action: #selector(buttonTapCanceled(_:)), for: .touchCancel)
    button.isUppercaseTitle = false
    return button
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(manageYourAccountButton)
    setupConstraints()
  }

  override var intrinsicContentSize: CGSize {
    let buttonSize = manageYourAccountButton.intrinsicContentSize
    return CGSize(width: buttonSize.width + 32, height: buttonSize.height + 4)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    manageYourAccountButton.layer.cornerRadius = manageYourAccountButton.frame.size.height / 2
    manageYourAccountButton.titleLabel?.preferredMaxLayoutWidth =
        manageYourAccountButton.titleLabel?.frame.size.width ?? 0
    manageYourAccountButton.layer.borderColor =
        UIColor(red: 218 / 255, green: 220 / 255, blue: 224 / 255, alpha: 1).cgColor
    manageYourAccountButton.layer.borderWidth = 1
    super.layoutSubviews()
  }

  @objc private func manageAccountButtonTapped(_ sender: Any) {
    guard let url = URL(string: "https://myaccount.google.com/") else { return }
    UIApplication.shared.openURL(url)
  }

  @objc private func buttonTapCanceled(_ sender: Any) {
    setNeedsLayout()
  }

  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: manageYourAccountButton,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .top,
                         multiplier: 1,
                         constant: 2),
      NSLayoutConstraint(item: manageYourAccountButton,
                         attribute: .leading,
                         relatedBy: .greaterThanOrEqual,
                         toItem: self,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: manageYourAccountButton,
                         attribute: .trailing,
                         relatedBy: .lessThanOrEqual,
                         toItem: self,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: manageYourAccountButton,
                         attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: manageYourAccountButton,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 2)
    ]

    addConstraints(constraints)
  }

  private lazy var heightConstraint = NSLayoutConstraint(item: self,
                                                         attribute: .height,
                                                         relatedBy: .equal,
                                                         toItem: nil,
                                                         attribute: .notAnAttribute,
                                                         multiplier: 1,
                                                         constant: 0)

}
