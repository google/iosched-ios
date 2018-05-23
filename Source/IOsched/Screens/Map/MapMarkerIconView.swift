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
    static let labelCornerRadius: CGFloat = 2
    static let labelFont = UIFont.mdc_preferredFont(forMaterialTextStyle: .caption)

    static let selectedMarkerColor = UIColor(red: 61.0 / 255.0, green: 90.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0)
    static let unselectedMarkerColor = UIColor(red: 0.61, green: 0.61, blue: 0.61, alpha: 1.0)
    static let titleButtonBackgroundColor = UIColor(red: 66 / 255, green: 133 / 255, blue: 244 / 255, alpha: 1.0)

    static func defaultImage() -> UIImage {
      return UIImage(named: "ic_place")!
    }
  }

  // MARK: - Properties

  private let imageView: UIImageView
  private let titleButton = UIButton()
  private let mapItem: MapItemViewModel
  let shouldHideTitleButton: Bool

  func shouldShowTitleButton(zoomLevel: Float, mapViewSize: CGSize) -> Bool {
    if let displayZoomLevel = mapItem.displayZoomLevel {
      return zoomLevel >= displayZoomLevel
    }

    let contentArea: Float
    if titleButton.isHidden {
      contentArea = Float(imageView.frame.size.width * imageView.frame.size.height)
    } else {
      contentArea = Float(titleButton.intrinsicContentSize.width
        * titleButton.intrinsicContentSize.height)
    }

    let latitude = mapItem.latitude
    let metersPerPoint = Float(cos(latitude * Double.pi / 180) * 2 * Double.pi * 6378137)
        / (256 * powf(2, zoomLevel))

    let approximateContentSizeInSquareMeters = metersPerPoint * contentArea

    // Amphitheatre + parking lots is approx. 800m by 600m, measured in Google Maps.
    let approximateVenueArea: Float = 800 * 600
    // Cap the considered area size at the total venue size. This way when zooming out
    // the icons won't all bunch together.
    let boundedViewportArea = min(Float(mapViewSize.width * mapViewSize.height),
                                  approximateVenueArea)

    // Don't show the label/button if it takes up more than a certain portion of the map area.
    let visibilityThreshold: Float = 0.015
    let thresholdScalar: Float = 1 - zoomLevel / 36
    let compositeThreshold = visibilityThreshold * thresholdScalar

    // The percentage of the screen that the content is taking up.
    let contentFootprintRatio = approximateContentSizeInSquareMeters / boundedViewportArea

    let shouldShow = contentFootprintRatio < compositeThreshold
    return shouldShow
  }

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
        titleButton.isHidden = false
      } else {
        imageView.tintColor = Constants.unselectedMarkerColor
        titleButton.isHidden = shouldHideTitleButton
      }
    }
  }

  init(frame: CGRect, mapItem: MapItemViewModel) {
    self.mapItem = mapItem
    imageView = UIImageView()
    if let iconName = mapItem.iconName, let image = UIImage(named: iconName) {
      imageView.image = image
      shouldHideTitleButton = true
    } else {
      imageView.image = Constants.defaultImage()
      shouldHideTitleButton = false
    }
    imageView.tintColor = Constants.unselectedMarkerColor
    super.init(frame: frame)

    isOpaque = false
    addSubview(imageView)
    addSubview(titleButton)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    titleButton.translatesAutoresizingMaskIntoConstraints = false

    imageView.contentMode = .scaleAspectFit

    titleButton.titleLabel?.font = Constants.labelFont
    titleButton.titleLabel?.enableAdjustFontForContentSizeCategory()
    titleButton.setTitleColor(.white, for: .normal)
    titleButton.backgroundColor = Constants.titleButtonBackgroundColor
    titleButton.contentEdgeInsets = Constants.labelPadding
    titleButton.isUserInteractionEnabled = false
    titleButton.layer.cornerRadius = Constants.labelCornerRadius
    titleButton.isHidden = shouldHideTitleButton

    let views: [String: UIView] = ["imageView": imageView, "titleButton": titleButton]
    var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[titleButton]-3-[imageView]|", options: [], metrics: nil, views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleButton]|", options: [], metrics: nil, views: views)
    constraints += [
      titleButton.heightAnchor.constraint(equalToConstant: CGFloat(Constants.labelHeight))
    ]
    constraints += [
      NSLayoutConstraint(item: imageView,
                         attribute: .width,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 24),
      NSLayoutConstraint(item: imageView,
                         attribute: .height,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 24),
      NSLayoutConstraint(item: imageView,
                         attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerX,
                         multiplier: 1,
                         constant: 0)
    ]
    NSLayoutConstraint.activate(constraints)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
