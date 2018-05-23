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
import MaterialComponents

class ScheduleViewTagContainerView: TagContainerView {

  var viewModel: [TagEventViewModel]? {
    didSet {
      switch (viewModel, oldValue) {
      case (.none, .none):
        break // nothing
      case (.none, .some):
        updateFromViewModel()
      case (.some, .none):
        updateFromViewModel()
      case (.some, .some):
        guard let viewModel = viewModel, let oldModel = oldValue else {
          // nothing
          break
        }
        if viewModel != oldModel {
          updateFromViewModel()
        }
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    updateFromViewModel()
  }

  fileprivate func updateFromViewModel() {
    defer {
      invalidateIntrinsicContentSize()
    }

    guard let viewModel = viewModel else {
      for view in subviews {
        view.removeFromSuperview()
      }
      return
    }

    // determine number of additional (or superfluous) buttons
    let difference = subviews.count - viewModel.count
    if difference > 0 {
      // remove any superfluous buttons
      for view in subviews.suffix(difference).reversed() {
        view.removeFromSuperview()
      }
    }
    else if difference < 0 {
      // add required number of buttons
      for _ in 0 ..< (-difference) {
        let newTagButton = TagButton()
        newTagButton.translatesAutoresizingMaskIntoConstraints = false
        newTagButton.isUppercaseTitle = false
        self.addSubview(newTagButton)
      }
    }

    var index = 0
    for tag in viewModel {
      guard let tagButton = subviews[index] as? TagButton else {
        continue
      }
      tagButton.setElevation(ShadowElevation(rawValue: 0), for: UIControlState())
      tagButton.setTitle(tag.name, for: .normal)
      let color = UIColor(hex: tag.color)
      tagButton.setBackgroundColor(color, for: .normal)

      index += 1
    }
  }

}
