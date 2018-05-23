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

protocol MapCardViewDelegate: class {
  func viewDidTapDismiss()
}

class MapCardView: UIView {

  private enum Constants {
    static let titleFont = MDCTypography.fontLoader().regularFont(ofSize: 18)
    static let titleColor = MDCPalette.grey.tint800
    static let detailFont = MDCTypography.fontLoader().regularFont(ofSize: 15)
    static let detailColor = MDCPalette.grey.tint800
    static let cornerRadius = CGFloat(3)
    static let cardElevation = ShadowElevation(rawValue: 4)
    static let buttonTextColor = UIColor(red:0.34, green:0.46, blue:0.96, alpha:1.0)
    static let dismissButtonTitle =
        NSLocalizedString("Dismiss",
                          comment: "Button title that will dismiss info text about a map location.")
  }

  private lazy var titleLabel: UILabel = self.setupTitleLabel()
  private lazy var detailLabel: UILabel = self.setupDetailLabel()

  weak var delegate: MapCardViewDelegate?

  var title: String? {
    didSet {
      titleLabel.text = title
    }
  }

  var details: String? {
    didSet {
      detailLabel.text = details
    }
  }

  override class var layerClass: AnyClass {
    return MDCShadowLayer.self
  }

  var shadowLayer: MDCShadowLayer {
    return self.layer as! MDCShadowLayer
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    setupViews()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupTitleLabel() -> UILabel {
    let titleLabel = UILabel()
    titleLabel.font = Constants.titleFont
    titleLabel.textColor = Constants.titleColor
    return titleLabel
  }

  func setupDetailLabel() -> UILabel {
    let detailLabel = UILabel()
    detailLabel.font = Constants.detailFont
    detailLabel.textColor = Constants.detailColor
    detailLabel.numberOfLines = 0
    return detailLabel
  }

  func setupDismissButton() -> MDCFlatButton {
    let dismissButton = MDCFlatButton()
    dismissButton.setTitleColor(Constants.buttonTextColor, for: .normal)
    dismissButton.setTitle(Constants.dismissButtonTitle, for: .normal)
    dismissButton.sizeToFit()
    dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
    return dismissButton
  }

  func setupViews() {
    backgroundColor = .white

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)

    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(detailLabel)

    let dismissButton = self.setupDismissButton()
    dismissButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(dismissButton)

    let views: [String: UIView] = ["title": titleLabel, "details": detailLabel, "dismiss": dismissButton]
    var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[title]-14-|",
                                                     options: [],
                                                     metrics: nil,
                                                     views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[details]-14-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[dismiss]-16-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-18-[title]-2-[details]-14-[dismiss]-16-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    NSLayoutConstraint.activate(constraints)

    layer.cornerRadius = Constants.cornerRadius
    shadowLayer.elevation = Constants.cardElevation
  }

  @objc func dismiss() {
    delegate?.viewDidTapDismiss()
  }
}
