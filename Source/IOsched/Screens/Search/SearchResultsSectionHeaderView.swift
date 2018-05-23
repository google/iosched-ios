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

class SearchResultsSectionHeaderView: UICollectionReusableView {

  private let label = UILabel()

  public var title: String {
    get {
      return label.text ?? ""
    }
    set {
      label.text = newValue
    }
  }

  static var headerHeight: CGFloat {
    return titleFont().pointSize + 32
  }

  private static func titleFont() -> UIFont {
    return UIFont.preferredFont(forTextStyle: .title2)
  }

  /// The current font. This may change when the accessibility font size changes.
  private var currentFont: UIFont {
    return SearchResultsSectionHeaderView.titleFont()
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .white
    addSubview(label)
    setupLabel()
  }

  private func setupLabel() {
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = currentFont
    label.enableAdjustFontForContentSizeCategory()

    let constraints = [
      NSLayoutConstraint(item: label,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .top,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: label,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .left,
                         multiplier: 1,
                         constant: 16)
    ]

    let lowPriorityConstraints = [
      NSLayoutConstraint(item: label,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .right,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: label,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -16)
    ]

    // The header may collapse if the section is emptied out, so the bottom/right constraints
    // must be lower priority to avoid ambiguous layouts.
    lowPriorityConstraints.forEach { $0.priority = .defaultLow }

    addConstraints(constraints)
  }

  override var intrinsicContentSize: CGSize {
    let labelSize = label.intrinsicContentSize
    return CGSize(width: labelSize.width + 32, height: labelSize.height + 32)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
