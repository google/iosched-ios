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

import UIKit

class ScheduleCollectionEmptyView: UIView {

  private lazy var textLabel: UILabel = self.setupTextLabel()
  private lazy var logoView: UIImageView = self.setupLogoView()
  private var emptyMyIOText: String
  private var emptyFilterText: String
  private lazy var logo: UIImage = {
    return UIImage(named: "logo")!
  }()

  override init(frame: CGRect) {
    emptyMyIOText = NSLocalizedString("Your starred and reserved events will appear here.",
                                      comment: "String describing an empty saved events section")
    emptyFilterText = NSLocalizedString("There aren't any events that match your filters.",
                                        comment: "String describing empty filter result.")
    super.init(frame: frame)

    addSubview(textLabel)
    addSubview(logoView)

    addConstraints(textLabelConstraints)
    addConstraints(logoViewConstraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported.")
  }

  func configureForMyIO() -> UIView {
    self.textLabel.text = emptyMyIOText
    return self
  }

  func configureForEmptyFilter() -> UIView {
    self.textLabel.text = emptyFilterText
    return self
  }

  private func setupTextLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hex: "#747474")
    label.font = UIFont.preferredFont(forTextStyle: .body)
    label.enableAdjustFontForContentSizeCategory()
    label.text = emptyMyIOText
    label.numberOfLines = 0
    label.textAlignment = .center
    label.lineBreakMode = .byWordWrapping
    return label
  }

  private func setupLogoView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = logo
    imageView.contentMode = .scaleAspectFit
    return imageView
  }

  private var textLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: textLabel, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: textLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: logoView, attribute: .bottom,
                         multiplier: 1, constant: 20),
      NSLayoutConstraint(item: textLabel, attribute: .leading,
                         relatedBy: .equal,
                         toItem: self, attribute: .leading,
                         multiplier: 1, constant: 8),
      NSLayoutConstraint(item: textLabel, attribute: .trailing,
                         relatedBy: .equal,
                         toItem: self, attribute: .trailing,
                         multiplier: 1, constant: -8)
    ]
  }

  private var logoViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: logoView, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: logoView, attribute: .centerY,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1, constant: -20),
      NSLayoutConstraint(item: logoView, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: logo.size.width),
      NSLayoutConstraint(item: logoView, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: logo.size.height)
    ]
  }

}
