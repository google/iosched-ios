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

import MaterialComponents

class NoAnnouncementsBackgroundView: UIView {

  let label: UILabel = {
    let label = UILabel()
    label.font = ProductSans.regular.style(.body)
    label.text = NSLocalizedString("There's no announcements to show right now.",
                                   comment: "Hint for empty announcements screen")
    label.numberOfLines = 2
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(r: 32, g: 33, b: 36)
    label.textAlignment = .center
    return label
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(label)
    setupConstraints()
  }

  private func setupConstraints() {
    let constraints: [NSLayoutConstraint] = [
      NSLayoutConstraint(item: label,
                         attribute: .centerY,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: label,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 32),
      NSLayoutConstraint(item: label,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -32)
    ]

    addConstraints(constraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

class NoAnnouncementsCollectionViewCell: UICollectionViewCell {

  static var height: CGFloat {
    return 140
  }

  private lazy var noAnnouncementsView = NoAnnouncementsBackgroundView(frame: contentView.frame)

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(noAnnouncementsView)
    noAnnouncementsView.translatesAutoresizingMaskIntoConstraints = false
    setupConstraints()
  }

  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: noAnnouncementsView, attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .top,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: noAnnouncementsView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .bottom,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: noAnnouncementsView, attribute: .left,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .left,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: noAnnouncementsView, attribute: .right,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .right,
                         multiplier: 1, constant: 0)
    ]

    contentView.addConstraints(constraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
