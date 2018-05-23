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

class HomeMomentView: UIView {

  let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()

  let timeLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 1
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.preferredFont(forTextStyle: .caption1)
    label.enableAdjustFontForContentSizeCategory()
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(imageView)
    addSubview(timeLabel)
    setupConstraints()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if imageView.frame.size.width > imageView.frame.size.height * (740 / 436) {
      imageView.contentMode = .scaleAspectFit
    } else {
      imageView.contentMode = .scaleAspectFill
    }
  }

  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: imageView, attribute: .centerY,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1, constant: 16),
      NSLayoutConstraint(item: imageView, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .left,
                         multiplier: 1, constant: 16),
      NSLayoutConstraint(item: imageView, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .right,
                         multiplier: 1, constant: -16),
      NSLayoutConstraint(item: imageView, attribute: .height,
                         relatedBy: .lessThanOrEqual,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: 218),
      NSLayoutConstraint(item: timeLabel, attribute: .leading,
                         relatedBy: .equal,
                         toItem: imageView, attribute: .leading,
                         multiplier: 1, constant: 16),
      NSLayoutConstraint(item: timeLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: imageView, attribute: .top,
                         multiplier: 1, constant: 16)
    ]

    let aspectRatioConstraint = NSLayoutConstraint(item: imageView, attribute: .height,
                                                   relatedBy: .equal,
                                                   toItem: imageView, attribute: .width,
                                                   multiplier: 436 / 740, constant: 0)
    aspectRatioConstraint.priority = .defaultLow

    addConstraints(constraints)
    addConstraint(aspectRatioConstraint)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
