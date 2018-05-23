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

class HeaderStack: UIView {
  private var views = [UIView]()

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let totalHeight = views.map { $0.sizeThatFits(size).height }.reduce(0, +)
    return CGSize(width: size.width, height: totalHeight)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Layout bottom to top using each item's size.
    var remainingSize = bounds.size
    for view in views.reversed() {
      let viewHeight = view.sizeThatFits(remainingSize).height
      let y = max(0, remainingSize.height - viewHeight)
      let height = min(viewHeight, remainingSize.height)
      view.frame = CGRect(x: 0, y: y, width: remainingSize.width, height: height)
      remainingSize = CGSize(width: remainingSize.width, height: remainingSize.height - height)
    }
  }

  func add(view: UIView) {
    views.append(view)
    addSubview(view)
  }
}
