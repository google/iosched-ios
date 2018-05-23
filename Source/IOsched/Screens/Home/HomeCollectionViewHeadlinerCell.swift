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
import AlamofireImage

public class HomeCollectionViewHeadlinerCell: UICollectionViewCell {

  public var headlinerView: UIView? {
    didSet {
      if oldValue == headlinerView { return }
      oldValue?.removeFromSuperview()

      if let view = headlinerView {
        contentView.addSubview(view)
        addConstraints(for: view)
      }
    }
  }

  public func populate(moment: Moment) {
    print(moment)
    let momentView: HomeMomentView
    if let view = headlinerView as? HomeMomentView {
      momentView = view
    } else {
      momentView = HomeMomentView(frame: contentView.bounds)
      headlinerView = momentView
    }

    momentView.imageView.af_setImage(withURL: moment.imageURL)
    momentView.timeLabel.isHidden = true // See b/130523107
    momentView.accessibilityHint = moment.accessibilityHint
    momentView.accessibilityLabel = moment.accessibilityLabel
  }

  public static var cellHeight: CGFloat {
    return CountdownView.contentSize.height
  }

  public override func prepareForReuse() {
    if let countdown = headlinerView as? CountdownView {
      countdown.stop()
    }
  }

  public override var intrinsicContentSize: CGSize {
    return headlinerView?.intrinsicContentSize ?? super.intrinsicContentSize
  }

  private func addConstraints(for subview: UIView) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    contentView.addConstraints(constraints(for: subview))
  }

  private func constraints(for view: UIView) -> [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: view,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .top,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: view,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: view,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .right,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: view,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 0)
    ]
  }

}
