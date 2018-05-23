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

import Foundation
import MaterialComponents

class TagButton: MDCRaisedButton {

  enum Constants {
    static let cornerRadius: CGFloat = 12
    static let fontSize: CGFloat  = 12
    static let intrinsicHeight: CGFloat = 24
    static let lightTitleColor = UIColor.white
    static let darkTitleColor = UIColor(hex: "#202124")
  }

  var cornerRadius: CGFloat = Constants.cornerRadius

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    setTitleFont(MDCTypography.fontLoader().mediumFont(ofSize: Constants.fontSize),
                 for: .normal)
  }

  override func setBackgroundColor(_ backgroundColor: UIColor?, for state: UIControlState) {
    super.setBackgroundColor(backgroundColor, for: state)
    guard let backgroundColor = backgroundColor else {
      setTitleColor(Constants.darkTitleColor, for: state)
      return
    }

    if backgroundColor.shouldDisplayDarkText {
      setTitleColor(Constants.darkTitleColor, for: state)
    } else {
      setTitleColor(Constants.lightTitleColor, for: state)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(width: size.width, height: Constants.intrinsicHeight)
  }

  override var accessibilityTraits: UIAccessibilityTraits {
    get {
      return isUserInteractionEnabled
        ? UIAccessibilityTraitButton
        : UIAccessibilityTraitStaticText
    }
    set {
    }
  }
}
