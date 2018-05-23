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

class AgendaSectionHeaderReusableView: UICollectionReusableView {

  private static let accessibilityFormatter: DateFormatter = {
    let formatter = TimeZoneAwareDateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter
  }()

  var date: Date? {
    didSet {
      if let value = date {
        let formatted = AgendaSectionHeaderReusableView.accessibilityFormatter.string(from: value)
        timeLabel.text = formatted
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(timeLabel)
    setupTimeLabelConstraints()
  }

  private let timeLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 1
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = ProductSans.regular.style(.body)
    label.enableAdjustFontForContentSizeCategory()
    return label
  }()

  public static var heightForContents: CGFloat {
    return ProductSans.regular.style(.body).lineHeight + 40
  }

  private func setupTimeLabelConstraints() {
    let constraints = [
      NSLayoutConstraint(item: timeLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: timeLabel,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: timeLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .top,
                         multiplier: 1,
                         constant: 20),
      NSLayoutConstraint(item: timeLabel,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -20)
    ]

    addConstraints(constraints)
  }

  // MARK: - UIAccessibility

  override var accessibilityLabel: String? {
    get {
      guard let date = date else { return nil }
      return AgendaSectionHeaderReusableView.accessibilityFormatter.string(from: date)
    } set {}
  }

  // MARK: - Dead code

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
