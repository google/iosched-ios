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

class CountdownCollectionViewCell: MDCCollectionViewCell {

  let countdownView = CountdownView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    countdownView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(countdownView)
    addConstraints(countdownConstraints(countdownView))
    countdownView.play()
    isUserInteractionEnabled = false
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  public static let reuseIdentifier = "CountdownCollectionViewCell"

  private func countdownConstraints(_ countdownView: UIView) -> [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: countdownView, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: countdownView, attribute: .centerY,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1, constant: 0),
    ]
  }

  public static var sizeForContents: CGSize {
    return CGSize(width: 300, height: 300)
  }

  deinit {
    countdownView.stop()
  }

}
