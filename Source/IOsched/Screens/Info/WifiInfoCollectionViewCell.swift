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

/// Class does nothing but display static information on the venue wifi.
class WifiInfoCollectionViewCell: MDCCollectionViewCell {

  struct Constants {
    // Horizontal inset is 16pt, vertical inset is 32.
    static let insets = CGPoint(x: 16, y: 32)
    static let interItemVerticalSpacing: CGFloat = 20

    // These may change before ship.
    static let wifi = NSLocalizedString("Wifi network:", comment: "Wifi network name label")
    static let wifiName = "io2019"
    static let password = NSLocalizedString("Password", comment: "Wifi network password label")
    static let passwordValue = "makegoodthings"

    static func labelFont() -> UIFont {
      return UIFont.preferredFont(forTextStyle: .subheadline)
    }
    static func valueFont() -> UIFont {
      return UIFont.preferredFont(forTextStyle: .subheadline)
    }

    static let labelTextColor = UIColor(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)
    static let valueTextColor = UIColor(red: 74 / 255, green: 74 / 255, blue: 74 / 255, alpha: 1)
  }

  static let wifiPassword = Constants.passwordValue

  private let wifiLabel = UILabel()
  private let wifiNameLabel = UILabel()

  private let passwordLabel = UILabel()
  private let passwordValueLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(wifiLabel)
    setupWifiLabel()
    contentView.addSubview(passwordLabel)
    setupPasswordLabel()
    contentView.addSubview(wifiNameLabel)
    setupWifiNameLabel()
    contentView.addSubview(passwordValueLabel)
    setupPasswordValueLabel()
    setupViewConstraints()
  }

  static var minimumHeightForContents: CGFloat {
    let wifiSize = Constants.wifiName.size(withAttributes: [NSAttributedString.Key.font: Constants.valueFont()])
    let passwordSize = Constants.passwordValue.size(withAttributes: [NSAttributedString.Key.font: Constants.valueFont()])

    return CGFloat(Constants.insets.y * 2
        + wifiSize.height
        + Constants.interItemVerticalSpacing
        + passwordSize.height)
  }

  // MARK: - layout code

  private func setupWifiLabel() {
    wifiLabel.text = Constants.wifi
    wifiLabel.font = Constants.labelFont()
    wifiLabel.textColor = Constants.labelTextColor

    wifiLabel.numberOfLines = 1
    wifiLabel.allowsDefaultTighteningForTruncation = true
    wifiLabel.translatesAutoresizingMaskIntoConstraints = false
    wifiLabel.enableAdjustFontForContentSizeCategory()
  }

  private func setupPasswordLabel() {
    passwordLabel.text = Constants.password
    passwordLabel.font = Constants.labelFont()
    passwordLabel.textColor = Constants.labelTextColor

    passwordLabel.numberOfLines = 1
    passwordLabel.allowsDefaultTighteningForTruncation = true
    passwordLabel.translatesAutoresizingMaskIntoConstraints = false
    passwordLabel.enableAdjustFontForContentSizeCategory()
  }

  private func setupWifiNameLabel() {
    wifiNameLabel.text = Constants.wifiName
    wifiNameLabel.font = Constants.valueFont()
    wifiNameLabel.textColor = Constants.valueTextColor

    wifiNameLabel.numberOfLines = 1
    wifiNameLabel.allowsDefaultTighteningForTruncation = true
    wifiNameLabel.translatesAutoresizingMaskIntoConstraints = false
    wifiNameLabel.enableAdjustFontForContentSizeCategory()
  }

  private func setupPasswordValueLabel() {
    passwordValueLabel.text = Constants.passwordValue
    passwordValueLabel.font = Constants.valueFont()
    passwordValueLabel.textColor = Constants.valueTextColor

    passwordValueLabel.numberOfLines = 1
    passwordValueLabel.allowsDefaultTighteningForTruncation = true
    passwordValueLabel.translatesAutoresizingMaskIntoConstraints = false
    passwordValueLabel.enableAdjustFontForContentSizeCategory()
  }

  private func setupViewConstraints() {
    var constraints = [NSLayoutConstraint]()

    // wifi label top
    constraints.append(NSLayoutConstraint(item: wifiLabel,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: 32))
    // wifi label left
    constraints.append(NSLayoutConstraint(item: wifiLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 16))
    // password label top
    constraints.append(NSLayoutConstraint(item: passwordLabel,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: -32))
    // password label left
    constraints.append(NSLayoutConstraint(item: passwordLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 16))
    // wifi name label bottom
    constraints.append(NSLayoutConstraint(item: wifiNameLabel,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: wifiLabel,
                                          attribute: .centerY,
                                          multiplier: 1,
                                          constant: 0))
    // wifi name label top
    constraints.append(NSLayoutConstraint(item: wifiNameLabel,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -16))
    // password value label bottom
    constraints.append(NSLayoutConstraint(item: passwordValueLabel,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: passwordLabel,
                                          attribute: .centerY,
                                          multiplier: 1,
                                          constant: 0))
    // password value label top
    constraints.append(NSLayoutConstraint(item: passwordValueLabel,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -16))

    wifiLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    passwordLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    contentView.addConstraints(constraints)
  }

  @available(*, unavailable)
  required init(coder aDecoder: NSCoder) {
    fatalError("NSCoding not supported for cell of type \(WifiInfoCollectionViewCell.self)")
  }

}

// MARK: - Accessibility

extension WifiInfoCollectionViewCell {

  override var isAccessibilityElement: Bool {
    get {
      return true
    } set {}
  }

  override var accessibilityLabel: String? {
    get {
      return NSLocalizedString(
        "IO event wifi password. Network name: io2018. Password: makegoodthings. Double-tap to copy password to clipboard.",
        comment: "Accessible description for the wifi info cell. Visually-impaired users will hear this text read to them via VoiceOver"
      )
    } set {}
  }

}
