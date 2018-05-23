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
    static let titleFont = ProductSans.regular.style(.callout)
    static let titleColor = UIColor(red: 20 / 255, green: 21 / 255, blue: 24 / 255, alpha: 1)
    static let detailFont = ProductSans.regular.style(.footnote)
    static let detailColor = UIColor(hex: 0x5f6368)
    static let cornerRadius = CGFloat(8)
    static let cardElevation = ShadowElevation(rawValue: 4)
    static let buttonTextColor = UIColor(red: 0.34, green: 0.46, blue: 0.96, alpha: 1.0)
    static let dismissButtonTitle =
        NSLocalizedString("Dismiss",
                          comment: "Button title that will dismiss info text about a map location.")
  }

  private lazy var titleLabel: UILabel = self.setupTitleLabel()
  private lazy var detailTextView: UITextView = self.setupDetailTextView()

  private lazy var detailTextViewHeightConstraint = NSLayoutConstraint(item: detailTextView,
                                                                       attribute: .height,
                                                                       relatedBy: .equal,
                                                                       toItem: nil,
                                                                       attribute: .notAnAttribute,
                                                                       multiplier: 1,
                                                                       constant: 0)

  weak var delegate: MapCardViewDelegate?

  var title: String? {
    didSet {
      titleLabel.text = composite(title: title, subtitle: subtitle)
    }
  }

  var subtitle: String? {
    didSet {
      titleLabel.text = composite(title: title, subtitle: subtitle)
    }
  }

  private func composite(title: String?, subtitle: String?) -> String {
    switch (title, subtitle) {
    case (nil, nil):
      return ""
    case (nil, let value?):
      return value
    case (let value?, nil):
      return value
    case (let lhs?, let rhs?):
      return lhs + ": " + rhs
    }
  }

  var details: String? {
    didSet {
      setHeightForTextView(with: details)
      guard let details = details else {
        detailTextView.attributedText = nil
        return
      }
      let attributedString = InfoDetail.attributedText(detail: details)
      detailTextView.attributedText = attributedString
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
    titleLabel.enableAdjustFontForContentSizeCategory()
    titleLabel.numberOfLines = 0
    return titleLabel
  }

  func setupDetailTextView() -> UITextView {
    let detailTextView = UITextView()
    detailTextView.textColor = Constants.detailColor
    detailTextView.isEditable = false
    detailTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
    detailTextView.textContainer.lineFragmentPadding = 0
    if #available(iOS 10, *) {
      detailTextView.adjustsFontForContentSizeCategory = true
    }
    return detailTextView
  }

  func setupDismissButton() -> MDCFlatButton {
    let dismissButton = MDCFlatButton()
    dismissButton.setTitleColor(Constants.buttonTextColor, for: .normal)
    dismissButton.setTitle(Constants.dismissButtonTitle, for: .normal)
    dismissButton.isUppercaseTitle = false
    dismissButton.sizeToFit()
    dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
    return dismissButton
  }

  func setupViews() {
    backgroundColor = .white

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)

    detailTextView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(detailTextView)

    let dismissButton = self.setupDismissButton()
    dismissButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(dismissButton)

    let views: [String: UIView] = ["title": titleLabel, "details": detailTextView, "dismiss": dismissButton]
    var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[title]-20-|",
                                                     options: [],
                                                     metrics: nil,
                                                     views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[details]-20-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[dismiss]-20-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[title]-16-[details]-14-[dismiss]-20-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    NSLayoutConstraint.activate(constraints)
    detailTextViewHeightConstraint.isActive = true

    layer.cornerRadius = Constants.cornerRadius
    shadowLayer.elevation = Constants.cardElevation
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let maxTitleLabelWidth = bounds.size.width - 28
    if titleLabel.preferredMaxLayoutWidth != maxTitleLabelWidth {
      titleLabel.preferredMaxLayoutWidth = maxTitleLabelWidth
      titleLabel.setNeedsLayout()
    }
  }

  private func setHeightForTextView(with detail: String?) {
    guard let detail = detail else {
      detailTextViewHeightConstraint.constant = 0
      return
    }
    guard let attributedString = InfoDetail.attributedText(detail: detail) else {
      detailTextViewHeightConstraint.constant = 0
      return
    }
    let inset: CGFloat = 40
    let maxHeight: CGFloat = 300
    let boundingSize = CGSize(width: frame.size.width - inset, height: .greatestFiniteMagnitude)
    let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesDeviceMetrics, .usesFontLeading]
    let textRect = attributedString.boundingRect(with: boundingSize,
                                                 options: options,
                                                 context: nil)
    let totalHeight = textRect.size.height.rounded(.up)
        + detailTextView.textContainerInset.top
        + detailTextView.textContainerInset.bottom
    let clampedHeight = min(totalHeight, maxHeight)
    detailTextViewHeightConstraint.constant = clampedHeight
    detailTextView.isScrollEnabled = totalHeight > maxHeight
  }

  @objc func dismiss() {
    delegate?.viewDidTapDismiss()
  }
}
