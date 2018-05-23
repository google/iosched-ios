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

class ExpandableSectionHeaderTextCell: MDCCollectionViewTextCell {

  private struct Constants {
    static let expanderColor = MDCPalette.grey.tint800
    static let moreImage = UIImage(named: "ic_expand_more")
    static let lessImage = UIImage(named: "ic_expand_less")
  }

  let expanderView: UIImageView

  var expanded = false {
    didSet {
      if expanded {
        expanderView.image = Constants.lessImage
      } else {
        expanderView.image = Constants.moreImage
      }
      expanderView.sizeToFit()

      self.accessoryView = expanderView
    }
  }

  override init(frame: CGRect) {
    expanderView = UIImageView()
    expanderView.tintColor = Constants.expanderColor
    expanded = false
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError("NSCoding not supported for cell of type \(ExpandableSectionHeaderTextCell.self)")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    if let textLabel = textLabel {
      textLabel.text = nil
    }
    expanded = false
  }
}
