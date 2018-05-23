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

class TagContainerView: UIView {

  enum Constants {
    static let xOffset: CGFloat = 8
    static let yOffset: CGFloat = 4
    static let tagHeight: CGFloat = 24
  }

  var preferredMaxLayoutWidth: CGFloat = 0

  override var intrinsicContentSize: CGSize {
    var totalRect = CGRect()
    iterateSubViews { (_, rect) in
      totalRect = totalRect.union(rect)
    }
    var size = totalRect.size
    size.height = max(size.height, Constants.tagHeight)

    // If there is no content, collapse the height.
    if size.width < 1 {
      size.height = 0
    }

    return size
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    iterateSubViews { (view, rect) in
      view.frame = rect
    }
  }

  private func iterateSubViews(callback: (_ view: UIView, _ rect: CGRect) -> Void) {
    let layoutWidth: CGFloat = preferredMaxLayoutWidth

    var x: CGFloat = 0
    var y: CGFloat = 0

    for view in self.subviews {
      if x > layoutWidth - view.intrinsicContentSize.width {
        y += view.intrinsicContentSize.height + Constants.yOffset
        x = 0
      }
      let rect = CGRect(x: x, y: y, width: view.intrinsicContentSize.width, height: view.intrinsicContentSize.height)
      callback(view, rect)

      x += view.intrinsicContentSize.width + Constants.xOffset
    }
  }

}
