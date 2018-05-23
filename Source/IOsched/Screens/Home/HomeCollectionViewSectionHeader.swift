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

class HomeCollectionViewSectionHeader: UICollectionReusableView {

  public var name: String? {
    get {
      return nameLabel.text
    }
    set {
      setText(newValue, for: nameLabel)
    }
  }

  public var title: String? {
    get {
      return titleLabel.text
    }
    set {
      setText(newValue, for: titleLabel)
    }
  }

  var horizontalTextPadding: CGFloat = 16

  private let nameLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 1
    label.translatesAutoresizingMaskIntoConstraints = false
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    label.font = UIFont.preferredFont(forTextStyle: .body)
    label.enableAdjustFontForContentSizeCategory()
    return label
  }()
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 1
    label.translatesAutoresizingMaskIntoConstraints = false
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    label.font = UIFont.preferredFont(forTextStyle: .footnote)
    label.enableAdjustFontForContentSizeCategory()
    return label
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(nameLabel)
    addSubview(titleLabel)

    setupConstraints()
  }

  public override var intrinsicContentSize: CGSize {
    guard !(name == nil && title == nil) else { return .zero }

    var constraintHeights: CGFloat = 0
    for constraint in constraints where constraint.firstAttribute == .top ||
      constraint.secondAttribute == .top ||
      constraint.firstAttribute == .bottom ||
      constraint.secondAttribute == .bottom {
        constraintHeights += abs(constraint.constant)
    }

    var constraintWidths: CGFloat = 0
    for constraint in constraints where constraint.firstAttribute == .leading ||
      constraint.secondAttribute == .leading ||
      constraint.firstAttribute == .trailing ||
      constraint.secondAttribute == .trailing ||
      constraint.firstAttribute == .left ||
      constraint.secondAttribute == .left ||
      constraint.firstAttribute == .right ||
      constraint.secondAttribute == .right {
        constraintWidths += abs(constraint.constant)
    }

    let totalWidth: CGFloat
    let totalHeight: CGFloat
    switch (name, title) {
    case (nil, _):
      totalWidth = titleLabel.intrinsicContentSize.width + constraintWidths
      totalHeight = titleLabel.intrinsicContentSize.height + constraintHeights
    case (_, nil):
      totalWidth = nameLabel.intrinsicContentSize.width + constraintWidths
      totalHeight = nameLabel.intrinsicContentSize.height + constraintHeights
    case (_, _):
      totalWidth = max(nameLabel.intrinsicContentSize.width, titleLabel.intrinsicContentSize.width)
          + constraintWidths
      totalHeight = nameLabel.intrinsicContentSize.height + titleLabel.intrinsicContentSize.height
          + constraintHeights
    }

    return CGSize(width: totalWidth, height: totalHeight)
  }

  public override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    let currentAttributes = super.preferredLayoutAttributesFitting(layoutAttributes).copy()
        as! UICollectionViewLayoutAttributes
    guard !(name == nil && title == nil) else {
      currentAttributes.frame = .zero
      return currentAttributes
    }
    currentAttributes.frame.size = intrinsicContentSize
    return currentAttributes
  }

  private func setText(_ text: String?, for label: UILabel) {
    label.text = text
    if text != nil {
      if label.superview == nil {
        addSubview(label)
      }
    } else {
      label.removeFromSuperview()
    }
    setupConstraints()
    setNeedsLayout()
  }

  private func setupConstraints() {
    removeConstraints(constraints)
    if name == nil && title == nil { return }

    let nameLabelBottomConstraint: NSLayoutConstraint
    if title != nil {
      nameLabelBottomConstraint =
        NSLayoutConstraint(item: nameLabel,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: titleLabel,
                           attribute: .top,
                           multiplier: 1,
                           constant: -8)
    } else {
      nameLabelBottomConstraint =
        NSLayoutConstraint(item: self,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: nameLabel,
                           attribute: .bottom,
                           multiplier: 1,
                           constant: 8)
    }

    let nameLabelConstraints = [
      NSLayoutConstraint(item: nameLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .top,
                         multiplier: 1,
                         constant: 20),
      NSLayoutConstraint(item: nameLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .leading,
                         multiplier: 1,
                         constant: horizontalTextPadding),
      NSLayoutConstraint(item: self,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: nameLabel,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: horizontalTextPadding),
      nameLabelBottomConstraint
    ]

    var titleLabelConstraints: [NSLayoutConstraint] = [
      NSLayoutConstraint(item: titleLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .leading,
                         multiplier: 1,
                         constant: horizontalTextPadding),
      NSLayoutConstraint(item: self,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: titleLabel,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: horizontalTextPadding),
      NSLayoutConstraint(item: self,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: titleLabel,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 8)
    ]
    if name == nil {
      titleLabelConstraints.append(NSLayoutConstraint(item: titleLabel,
                                                      attribute: .top,
                                                      relatedBy: .equal,
                                                      toItem: self,
                                                      attribute: .top,
                                                      multiplier: 1,
                                                      constant: 20))
    }

    if name != nil {
      addConstraints(nameLabelConstraints)
    }
    if title != nil {
      addConstraints(titleLabelConstraints)
    }
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
