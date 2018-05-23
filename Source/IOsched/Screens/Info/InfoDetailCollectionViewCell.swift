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

import MaterialComponents

class InfoDetailCollectionViewCell: MDCCollectionViewCell {

  fileprivate struct Constants {

    static let titleFont = { () -> UIFont in
      let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
      return UIFont.systemFont(ofSize: descriptor.pointSize, weight: UIFont.Weight.medium)
    }

    static let titleTextColor = UIColor(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)
    static let expandedTitleTextColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)

    static let arrowLayerColor = UIColor(red: 150 / 255, green: 150 / 255, blue: 150 / 255, alpha: 1)
    static let expandedArrowLayerColor = Constants.expandedTitleTextColor

    // We're using a layer instead of an image asset since for whatever reason
    // we have two differently-sized image assets (the images are the same
    // size, but the actual arrow in the image is smaller in the non-expanded
    // asset). This way, though, we get more animation power so it's not so bad.
    static func arrowLayer() -> CAShapeLayer {
      // This is a func instead of a let to make sure we're
      // returning a new layer every time and don't have to 
      // deal with shared layer state.
      let layer = CAShapeLayer()
      layer.frame = CGRect(x: 6, y: 0, width: 12, height: 12)

      var transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)

      let mutablePath = CGMutablePath()
      mutablePath.move(to: CGPoint(x: 2, y: 2))
      mutablePath.addLine(to: CGPoint(x: 10, y: 2))
      mutablePath.addLine(to: CGPoint(x: 10, y: 3))
      mutablePath.addLine(to: CGPoint(x: 3, y: 3))
      mutablePath.addLine(to: CGPoint(x: 3, y: 10))
      mutablePath.addLine(to: CGPoint(x: 2, y: 10))
      mutablePath.addLine(to: CGPoint(x: 2, y: 2))
      mutablePath.closeSubpath()

      let path = mutablePath.copy(using: &transform)

      layer.path = path

      layer.strokeColor = Constants.arrowLayerColor.cgColor
      layer.fillColor = Constants.arrowLayerColor.cgColor

      return layer
    }

    // Duplicated constraints because we're manually calculating cell height. Switch to auto cell
    // height, if possible.
    static let titleLabelInsets: (top: CGFloat, left: CGFloat, bottom: CGFloat) = (
      top: 16, left: 16, bottom: 16
    )

    static let detailViewTopInset: CGFloat = 64

    static let collapsedAccessibilityHint = NSLocalizedString("Double tap to expand", comment: "Accessible instructions for expanding cells in the Info screen")
    static let expandedAccessibilityHint = NSLocalizedString("Double tap to collapse", comment: "Accessible instructions for collapsing cells in the Info screen")
  }

  class ArrowIconView: UIView {
    var iconLayer: CAShapeLayer? {
      didSet {
        if let sublayers = layer.sublayers {
          sublayers.forEach {
            $0.removeFromSuperlayer()
          }
        }
        if let iconLayer = iconLayer {
          layer.addSublayer(iconLayer)
        }
      }
    }
  }

  /// The view that holds the expanded contents of the cell once it's tapped.
  fileprivate let detailViewContainer = UIView()

  /// The title of the cell. Always visible, regardless of whether or not cell is expanded.
  fileprivate let titleLabel = UILabel()

  fileprivate let arrowIconView = ArrowIconView()

  let detailView = InfoDetailView(frame: .zero)

  /// Sets the expanded contents of the cell.
  var detail: InfoDetail? {
    didSet {
      if let detail = detail {
        detailView.detail = detail
        setNeedsLayout()
      }
    }
  }

  func populate(detail: InfoDetail, expanded: Bool = false) {
    if expanded {
      self.expand()
    } else {
      self.collapse()
    }
    titleLabel.text = detail.title
    self.detail = detail
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(detailViewContainer)
    detailViewContainer.addSubview(detailView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(arrowIconView)
    clipsToBounds = true
    detailView.detailTextView.delegate = self

    setupTitleLabel()
    setupDetailViewContainer()
    setupDetailView()
    setupArrowIconView()
    setupConstraints()
    setupDetailViewConstraints(expanded: true)
  }

  static func minimumHeightForContents(withTitle title: String, maxWidth: CGFloat) -> CGFloat {
    let boundingSize = CGSize(width: maxWidth - 70, height: .greatestFiniteMagnitude)
    let options: NSStringDrawingOptions =
        [.usesLineFragmentOrigin, .usesDeviceMetrics, .usesFontLeading]
    let attributes = [NSAttributedString.Key.font: Constants.titleFont()]
    let titleSize = title.boundingRect(with: boundingSize,
                                       options: options,
                                       attributes: attributes,
                                       context: nil)
    return titleSize.height + Constants.titleLabelInsets.top + Constants.titleLabelInsets.bottom
  }

  static func fullHeightForContents(detail: InfoDetail,
                                    maxWidth: CGFloat) -> CGFloat {
    let width = maxWidth - Constants.titleLabelInsets.left * 2
    let titleHeight = minimumHeightForContents(withTitle: detail.title, maxWidth: maxWidth)
    let height = titleHeight + InfoDetailView.height(forDetailText: detail.detail,
                                                     maxWidth: width)
    return height
  }

  private func setupTitleLabel() {
    titleLabel.numberOfLines = 0
    titleLabel.lineBreakMode = .byWordWrapping
    titleLabel.font = Constants.titleFont()
    titleLabel.allowsDefaultTighteningForTruncation = true
    titleLabel.textColor = Constants.titleTextColor
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.accessibilityHint = Constants.collapsedAccessibilityHint
    titleLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
  }

  private func setupDetailViewContainer() {
    detailViewContainer.translatesAutoresizingMaskIntoConstraints = false
  }

  private func setupDetailView() {
    detailView.translatesAutoresizingMaskIntoConstraints = false
    detailView.detailTextView.isAccessibilityElement = false
  }

  fileprivate func setupDetailViewConstraints(expanded: Bool) {
    // remove all old constraints
    detailViewContainer.removeConstraints(detailViewContainer.constraints)

    var constraints: [NSLayoutConstraint] = []

    // detail view top
    constraints.append(NSLayoutConstraint(item: detailView,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: detailViewContainer,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: 0))
    // detail view left
    constraints.append(NSLayoutConstraint(item: detailView,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: detailViewContainer,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 0))
    // detail view right
    constraints.append(NSLayoutConstraint(item: detailView,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: detailViewContainer,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: 0))
    // detail view bottom
    constraints.append(NSLayoutConstraint(item: detailView,
                                          attribute: .bottom,
                                          relatedBy: .equal,
                                          toItem: detailViewContainer,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: 0))

    detailViewContainer.addConstraints(constraints)
  }

  private func setupArrowIconView() {
    arrowIconView.translatesAutoresizingMaskIntoConstraints = false
    arrowIconView.iconLayer = Constants.arrowLayer()
    arrowIconView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
  }

  private func setupConstraints() {
    var constraints: [NSLayoutConstraint] = []

    // title label left
    constraints.append(NSLayoutConstraint(item: titleLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 16))
    // title label right
    constraints.append(NSLayoutConstraint(item: titleLabel,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -54))
    // title label centerY
    constraints.append(NSLayoutConstraint(item: titleLabel,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: 16))
    // detail view top
    constraints.append(NSLayoutConstraint(item: detailViewContainer,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: 64))
    // detail view left
    constraints.append(NSLayoutConstraint(item: detailViewContainer,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 16))
    // detail view right
    constraints.append(NSLayoutConstraint(item: detailViewContainer,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -16))
    // icon view top
    constraints.append(NSLayoutConstraint(item: arrowIconView,
                                          attribute: .centerY,
                                          relatedBy: .equal,
                                          toItem: titleLabel,
                                          attribute: .centerY,
                                          multiplier: 1,
                                          constant: 0))
    // icon view right
    constraints.append(NSLayoutConstraint(item: arrowIconView,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -24))
    // icon view width
    constraints.append(NSLayoutConstraint(item: arrowIconView,
                                          attribute: .width,
                                          relatedBy: .equal,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1,
                                          constant: 12))
    // icon view height
    constraints.append(NSLayoutConstraint(item: arrowIconView,
                                          attribute: .height,
                                          relatedBy: .equal,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1,
                                          constant: 12))

    contentView.addConstraints(constraints)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Support dynamic type
    let font = Constants.titleFont()
    if font.pointSize != titleLabel.font.pointSize {
      titleLabel.font = font
    }
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError("NSCoding not supported for cell of type \(InfoDetailCollectionViewCell.self)")
  }

  // Removes ink animations on these views, since animating ink views while
  // expanding/contracting results in buggy ink animations.
  override var inkView: MDCInkView? {
    get { return nil }
    set {}
  }

  override func prepareForReuse() {
    super.prepareForReuse()
  }

  // MARK: - Accessibility

  fileprivate var expanded: Bool = false

  override var isAccessibilityElement: Bool {
    set {}
    get { return !expanded }
  }

  override var accessibilityLabel: String? {
    set {}
    get {
      return titleLabel.accessibilityLabel
    }
  }

  override var accessibilityHint: String? {
    set {}
    get {
      return NSLocalizedString("Double-tap to expand details.",
                               comment: "Accessibility hint instructing users how to read the contents of a FAQ/Travel item")
    }
  }

}

// MARK: - Collapse/Expand cells

extension InfoDetailCollectionViewCell {

  func expand() {
    expanded = true
    setupDetailViewConstraints(expanded: true)
    arrowIconView.transform = .identity
    titleLabel.textColor = Constants.expandedTitleTextColor
    titleLabel.accessibilityHint = Constants.expandedAccessibilityHint
    detailView.detailTextView.isAccessibilityElement = true

    if let iconLayer = arrowIconView.iconLayer {
      iconLayer.strokeColor = Constants.expandedArrowLayerColor.cgColor
      iconLayer.fillColor = Constants.expandedArrowLayerColor.cgColor
    }
    setNeedsLayout()
    if UIAccessibility.isVoiceOverRunning {
      UIAccessibility.post(notification: .layoutChanged, argument: detailView.detailTextView)
    }
  }

  func collapse() {
    expanded = false
    setupDetailViewConstraints(expanded: false)
    titleLabel.textColor = Constants.titleTextColor
    arrowIconView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
    titleLabel.accessibilityHint = Constants.collapsedAccessibilityHint
    detailView.detailTextView.isAccessibilityElement = false

    if let iconLayer = arrowIconView.iconLayer {
      iconLayer.strokeColor = Constants.arrowLayerColor.cgColor
      iconLayer.fillColor = Constants.arrowLayerColor.cgColor
    }
    setNeedsLayout()
  }

}

// MARK: - UITextFieldDelegate

extension InfoDetailCollectionViewCell: UITextViewDelegate {

  @available(iOS 10.0, *)
  func textView(_ textView: UITextView,
                shouldInteractWith url: URL,
                in characterRange: NSRange,
                interaction: UITextItemInteraction) -> Bool {
    // UIKit crashes our app if we try to preview an App Store link.
    if interaction == .preview && url.host == "itunes.apple.com" {
      UIApplication.shared.openURL(url)
      return false
    }
    return true
  }

  @available(iOS, deprecated: 10.0)
  func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
    if url.host == "itunes.apple.com" {
      UIApplication.shared.openURL(url)
      return false
    }
    return true
  }

}
