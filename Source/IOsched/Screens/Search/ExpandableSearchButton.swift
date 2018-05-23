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

public class ExpandableSearchButton: UIControl {

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .center
    imageView.image = UIImage(named: "ic_search")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(imageView)
    imageView.isUserInteractionEnabled = false
    setupConstraints()
  }

  private func setupConstraints() {
    let constraints: [NSLayoutConstraint] = [
      NSLayoutConstraint(item: imageView,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .top,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: imageView,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .left,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: imageView,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: imageView,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .right,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: imageView,
                         attribute: .width,
                         relatedBy: .greaterThanOrEqual,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 24),
      NSLayoutConstraint(item: imageView,
                         attribute: .height,
                         relatedBy: .greaterThanOrEqual,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 24),
      NSLayoutConstraint(item: imageView,
                         attribute: .height,
                         relatedBy: .equal,
                         toItem: imageView,
                         attribute: .width,
                         multiplier: 1,
                         constant: 0)
    ]

    addConstraints(constraints)

    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
  }

  public override var intrinsicContentSize: CGSize {
    return CGSize(width: 56, height: 56)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
