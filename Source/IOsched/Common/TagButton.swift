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
    static let lightTitleColor = UIColor.white
    static let darkTitleColor = UIColor(hex: "#202124")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    let font = UIFont.mdc_preferredFont(forMaterialTextStyle: .caption)
    setTitleFont(font, for: .normal)
    registerForDynamicTypeUpdates()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func setBackgroundColor(_ backgroundColor: UIColor?, for state: UIControl.State) {
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

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    let superSize = super.intrinsicContentSize
    guard let font = titleFont(for: .normal) else { return superSize }
    let height = font.lineHeight + 8
    return CGSize(width: superSize.width, height: height)
  }

  override var accessibilityTraits: UIAccessibilityTraits {
    get {
      return isUserInteractionEnabled
        ? UIAccessibilityTraits.button
        : UIAccessibilityTraits.staticText
    }
    set {
    }
  }

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    let font = UIFont.mdc_preferredFont(forMaterialTextStyle: .caption)
    setTitleFont(font, for: .normal)
    setNeedsLayout()
  }

}
