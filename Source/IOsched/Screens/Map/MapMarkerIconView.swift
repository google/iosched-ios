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

final class MapMarkerIconView: UIView {

  private enum Constants {
    static let labelPadding = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    static let labelHeight = 27
    static let labelCornerRadius: CGFloat = 27 / 2.0
    static let labelFont = MDCTypography.fontLoader().mediumFont(ofSize: 12)

    static let selectedMarkerColor = UIColor(red:61.0 / 255.0, green:90.0 / 255.0, blue:254.0 / 255.0, alpha:1.0)
    static let unselectedMarkerColor = UIColor(red:0.61, green:0.61, blue:0.61, alpha:1.0)
    static let titleButtonBackgroundColor = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.0)

    static func imageName(for mapItemType: MapItemType) -> String {
      switch mapItemType {
      case .ada:
        return "ic_ada"
      case .bar:
        return "ic_bar"
      case .bike:
        return "ic_bike"
      case .charging:
        return "ic_charging"
      case .dog:
        return "ic_dog"
      case .food:
        return "ic_food"
      case .info:
        return "ic_info"
      case .medical:
        return "ic_medical"
      case .parking:
        return "ic_parking"
      case .restroom:
        return "ic_restroom"
      case .ride:
        return "ic_rideshare"
      case .rideshare:
        return "ic_rideshare"
      case .shuttle:
        return "ic_shuttle"
      case .store:
        return "ic_store"
      case .press:
        return "ic_press_lounge"
      case .mothersRoom:
        return "ic_mothers_room"
      case .communityLounge:
        return "ic_community_lounge"
      case .certificationLounge:
        return "ic_certification_lounge"
      default:
        return "ic_place"
      }
    }
  }

  // MARK: - Properties

  private let imageView: UIImageView
  private let titleButton = UIButton()
  let mapItemType: MapItemType

  var title: String? {
    didSet {
      titleButton.setTitle(title, for: .normal)
      titleButton.sizeToFit()
      setNeedsUpdateConstraints()
    }
  }

  var selected = false {
    didSet {
      if selected {
        imageView.tintColor = Constants.selectedMarkerColor
      } else {
        imageView.tintColor = Constants.unselectedMarkerColor
      }
    }
  }

  init(frame: CGRect, mapItemType: MapItemType) {
    imageView = UIImageView(image:UIImage(named: Constants.imageName(for: mapItemType)))
    imageView.tintColor = Constants.unselectedMarkerColor
    self.mapItemType = mapItemType
    super.init(frame: frame)

    isOpaque = false
    addSubview(imageView)
    addSubview(titleButton)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    titleButton.translatesAutoresizingMaskIntoConstraints = false

    imageView.contentMode = .bottom

    titleButton.titleLabel?.font = Constants.labelFont
    titleButton.setTitleColor(.white, for: .normal)
    titleButton.backgroundColor = Constants.titleButtonBackgroundColor
    titleButton.contentEdgeInsets = Constants.labelPadding
    titleButton.isUserInteractionEnabled = false
    titleButton.layer.cornerRadius = Constants.labelCornerRadius

    let views: [String: UIView] = ["imageView": imageView, "titleButton": titleButton]
    var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[titleButton]-3-[imageView]|", options: [], metrics: nil, views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|", options: [], metrics: nil, views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleButton]|", options: [], metrics: nil, views: views)
    constraints += [
      titleButton.heightAnchor.constraint(equalToConstant: CGFloat(Constants.labelHeight))
    ]
    NSLayoutConstraint.activate(constraints)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
