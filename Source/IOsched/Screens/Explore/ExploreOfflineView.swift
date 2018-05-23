//
//  Copyright (c) 2019 Google Inc.
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

import UIKit

public class ExploreOfflineView: UIView {

  private enum Constants {

    static let title = NSLocalizedString("Could not load Explore mode", comment: "Title for the AR Explore screen if the user's phone failed to load")
    static let subtext = NSLocalizedString("Your device appears to be offline. To use Explore mode, try connecting to the conference WiFi:\n\nSSID: io2019\nPassword: makegoodthings", comment: "Subtext offering suggestions on how to connect to WiFi if the user's device is offline")

  }

  private let titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(red: 32 / 255, green: 33 / 255, blue: 36 / 255, alpha: 1)
    label.font = UIFont.preferredFont(forTextStyle: .headline)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.enableAdjustFontForContentSizeCategory()
    label.text = Constants.title
    return label
  }()

  private let subtextLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(red: 65 / 255, green: 69 / 255, blue: 73 / 255, alpha: 1)
    label.font = UIFont.preferredFont(forTextStyle: .subheadline)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.enableAdjustFontForContentSizeCategory()
    label.text = Constants.subtext
    return label
  }()

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.image = UIImage(named: "ar_offline")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white

    addSubview(titleLabel)
    addSubview(subtextLabel)
    addSubview(imageView)

    setupConstraints()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override var isAccessibilityElement: Bool {
    get { return true }
    set {}
  }

  public override var accessibilityLabel: String? {
    set {}
    get {
      return Constants.title + "\n" + Constants.subtext
    }
  }

  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: titleLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 18),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .leading,
                         relatedBy: .greaterThanOrEqual,
                         toItem: self,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .trailing,
                         relatedBy: .lessThanOrEqual,
                         toItem: self,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: subtextLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: titleLabel,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 12),
      NSLayoutConstraint(item: subtextLabel,
                         attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: subtextLabel,
                         attribute: .leading,
                         relatedBy: .greaterThanOrEqual,
                         toItem: titleLabel,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: subtextLabel,
                         attribute: .trailing,
                         relatedBy: .lessThanOrEqual,
                         toItem: titleLabel,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: imageView,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: -28),
      NSLayoutConstraint(item: imageView,
                         attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: imageView,
                         attribute: .width,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 162),
      NSLayoutConstraint(item: imageView,
                         attribute: .height,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 175)
    ]

    addConstraints(constraints)
  }

}
