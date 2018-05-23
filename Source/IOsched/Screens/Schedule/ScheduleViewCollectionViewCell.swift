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
import UIKit
import MaterialComponents

class ScheduleViewCollectionViewCell: MDCCollectionViewCell {

  private enum Constants {
    static let topMargin: CGFloat = 15
    static let bottomMargin: CGFloat = 22
    static let horizontalMargins: CGFloat = 4
    static let extendedRightMargin: CGFloat = 16
    static let reserveButtonPaddedWidth: CGFloat = 40
    static let tagContainerMaxLayoutWidth: CGFloat = 240
    static let priorityHigherThanHigh: Float = 751.0
    static let reservedIcon: UIImage? = UIImage(named: "ic_session_reserved")
    static let titleColor = "#424242"
    static let subtitleColor = "#747474"
    static let titleFont = "Product Sans"
  }

  private lazy var titleColor: UIColor = {
    return UIColor(hex: Constants.titleColor)
  }()

  private lazy var subtitleColor: UIColor = {
    return UIColor(hex: Constants.subtitleColor)
  }()

  private lazy var bookmarkButton: MDCButton = self.setupBookmarkButton()
  private lazy var breakVerticalConstraints = [NSLayoutConstraint]()
  private lazy var liveStreamVerticalConstraints = [NSLayoutConstraint]()
  private lazy var reserveButton: MDCButton = self.setupReserveButton()
  private lazy var tagBottomConstraint = self.setupTagBottomConstraint()
  private lazy var tagContainer: ScheduleViewTagContainerView = self.setupTagContainer()
  private lazy var tagCollapsedHeight: NSLayoutConstraint = self.setupTagCollapsedHeightConstraint()
  private lazy var timeAndLocationLabel: UILabel = self.setupTimeAndLocationLabel()
  private lazy var titleLabel: UILabel = self.setupTitleLabel()

  var viewModel: SessionViewModel? {
    didSet {
      updateFromViewModel()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var titleLabelFont: UIFont {
    let size = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
    let font = UIFont(name: Constants.titleFont, size: size)
    if let font = font {
      return font
    } else {
      return UIFont.mdc_preferredFont(forMaterialTextStyle: .subheadline)
    }
  }

  private var timeAndLocationLabelFont: UIFont {
    return UIFont.preferredFont(forTextStyle: .caption1)
  }

  private func setupTitleLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = titleLabelFont
    label.textColor = titleColor
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.contentMode = .top

    label.setContentCompressionResistancePriority(.required, for: .vertical)
    label.setContentHuggingPriority(.defaultLow, for: .horizontal)

    return label
  }

  private func setupTimeAndLocationLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = timeAndLocationLabelFont
    label.textColor = subtitleColor
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    return label
  }

  private func setupTagContainer() -> ScheduleViewTagContainerView {
    let tagContainer = ScheduleViewTagContainerView()
    tagContainer.translatesAutoresizingMaskIntoConstraints = false
    tagContainer.preferredMaxLayoutWidth = Constants.tagContainerMaxLayoutWidth
    tagContainer.setContentHuggingPriority(.defaultHigh, for: .vertical)
    return tagContainer
  }

  private func setupBookmarkButton() -> MDCButton {
    let bookmarkButton = MDCFlatButton()
    bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
    bookmarkButton.contentMode = .top
    bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
    bookmarkButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    bookmarkButton.setContentHuggingPriority(.required, for: .horizontal)
    return bookmarkButton
  }

  private func setupReserveButton() -> MDCButton {
    let reservedButton = MDCFlatButton()
    reservedButton.translatesAutoresizingMaskIntoConstraints = false
    reservedButton.addTarget(self, action: #selector(reserveTapped(_:)), for: .touchUpInside)
    reservedButton.contentMode = .center
    return reservedButton
  }

  private func setupTagCollapsedHeightConstraint() -> NSLayoutConstraint {
    let tagHeight = NSLayoutConstraint(item: tagContainer, attribute: .height,
                                       relatedBy: .equal,
                                       toItem: nil, attribute: .notAnAttribute,
                                       multiplier: 1, constant: 0)
    return tagHeight
  }

  private func setupTagBottomConstraint() -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint(item: tagContainer, attribute: .bottom,
                                        relatedBy: .equal,
                                        toItem: contentView, attribute: .bottom,
                                        multiplier: 1,
                                        constant: -1 * Constants.bottomMargin)
    return constraint
  }

  private func setupViews() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(timeAndLocationLabel)
    contentView.addSubview(tagContainer)
    contentView.addSubview(bookmarkButton)
    contentView.addSubview(reserveButton)

    let views = [
      "titleLabel": titleLabel,
      "timeAndLocationLabel": timeAndLocationLabel,
      "tagContainer": tagContainer,
      "bookmarkButton": bookmarkButton,
      "reserveButton": reserveButton
      ] as [String: Any]

    let metrics: [String: CGFloat] = [
      "topMargin": Constants.topMargin,
      "bottomMargin": Constants.bottomMargin,
      "leftMargin": Constants.horizontalMargins,
      "rightMargin": Constants.horizontalMargins,
      "extendedRightMargin": Constants.extendedRightMargin,
      "reserveButtonPaddedWidth": Constants.reserveButtonPaddedWidth
    ]

    var constraints =
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[titleLabel]-(reserveButtonPaddedWidth)-[bookmarkButton]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)
    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[timeAndLocationLabel]-(extendedRightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)
    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[tagContainer]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|-(topMargin)-[titleLabel]-[timeAndLocationLabel]-[tagContainer]",
                                     options: [],
                                     metrics: metrics,
                                     views: views)
    constraints.append(tagBottomConstraint)

    let tagLeading = NSLayoutConstraint(item: tagContainer, attribute: .leading,
                                        relatedBy: .equal,
                                        toItem: contentView, attribute: .leading,
                                        multiplier: 1, constant: 8)
    tagLeading.priority = UILayoutPriority.defaultLow
    constraints += [tagLeading]

    constraints += [
      NSLayoutConstraint(item: reserveButton, attribute: .trailing,
                         relatedBy: .equal,
                         toItem: bookmarkButton, attribute: .leading,
                         multiplier: 1, constant: 8),
      NSLayoutConstraint(item: reserveButton, attribute: .centerY,
                         relatedBy: .equal,
                         toItem: titleLabel, attribute: .centerY,
                         multiplier: 1, constant: 0)
    ]

    constraints += [NSLayoutConstraint(item: bookmarkButton, attribute: .centerY,
                                       relatedBy: .equal,
                                       toItem: titleLabel, attribute: .centerY,
                                       multiplier: 1, constant: 0)]

    let buttonHeightConstraints = [
      NSLayoutConstraint(item: reserveButton,
                         attribute: .height,
                         relatedBy: .greaterThanOrEqual,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 48),
      NSLayoutConstraint(item: bookmarkButton,
                         attribute: .height,
                         relatedBy: .greaterThanOrEqual,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 48)
    ]

    contentView.addConstraints(constraints)
    contentView.addConstraints(buttonHeightConstraints)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if UIAccessibility.isVoiceOverRunning {
      var frame = titleLabel.frame
      frame.size.height = bounds.size.height
      frame.origin.y = 0
      accessibilityView.frame = frame
    }
  }

  private func updateFromViewModel() {
    if let viewModel = viewModel {
      titleLabel.text = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
      timeAndLocationLabel.text = viewModel.timeAndLocation

      if viewModel.tags.count > 0 {
        tagContainer.isHidden = false
      } else {
        tagContainer.isHidden = true
      }

      bookmarkButton.setImage(viewModel.bookmarkButtonImage, for: .normal)
      bookmarkButton.accessibilityLabel = viewModel.bookmarkButtonAccessibilityLabel

      if viewModel.isReservable {
        reserveButton.isHidden = false
        reserveButton.setImage(viewModel.reserveButtonImage, for: .normal)
        reserveButton.accessibilityLabel = viewModel.reserveButtonAccessibilityLabel
      } else {
        reserveButton.isHidden = true
      }

      // Collapse events taking place at the Office Hours / App Review tent so they
      // take up less space.
      let session = viewModel.session
      if session.type == .appReviews || session.type == .gameReviews ||
          session.type == .officeHours {
        tagContainer.tags = []
        tagContainer.isHidden = true
      } else {
        tagContainer.tags = viewModel.topics
      }

      registerForDynamicTypeUpdates()
    }

    if UIAccessibility.isVoiceOverRunning {
      enableAccessibility()
    } else {
      removeAccessibilityOverlay()
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    NotificationCenter.default.removeObserver(self)
    viewModel = nil
    accessibilityView.removeFromSuperview()
  }

  func heightForContents(maxWidth: CGFloat) -> CGFloat {
    let titleWidth = maxWidth - Constants.horizontalMargins * 2 - Constants.reserveButtonPaddedWidth
        - bookmarkButton.intrinsicContentSize.width - 8 * 2
    let titleSize =
        titleLabel.sizeThatFits(CGSize(width: titleWidth,
                                       height: .greatestFiniteMagnitude))
    let timeAndLocationSize = timeAndLocationLabel
      .sizeThatFits(CGSize(width: maxWidth - (Constants.horizontalMargins + Constants.extendedRightMargin),
                           height: .greatestFiniteMagnitude))
    let componentHeights: [CGFloat] = [
      Constants.topMargin,
      titleSize.height,
      CGFloat(8),
      timeAndLocationSize.height,
      CGFloat(8),
      tagContainer.intrinsicContentSize.height,
      Constants.bottomMargin
    ]
    return componentHeights.reduce(CGFloat(0), +)
  }

  var onBookmarkTappedCallback: ((_ sessionID: String) -> Void)?
  func onBookmarkTapped(_ callback: @escaping (_ sessionID: String) -> Void) {
    self.onBookmarkTappedCallback = callback
  }

  @objc func bookmarkTapped() {
    guard let sessionID = viewModel?.id else { return }
    onBookmarkTappedCallback?(sessionID)
  }

  @objc func reserveTapped(_ sender: Any) {
    viewModel?.attemptReservationAction()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Accessibility

  private lazy var accessibilityView = UIView()
  private func enableAccessibility() {
    guard let viewModel = viewModel else { return }
    titleLabel.isAccessibilityElement = false
    timeAndLocationLabel.isAccessibilityElement = false
    tagContainer.disableAccessibilitySelect()

    let tagLabel = NSLocalizedString(
      "Topics:",
      comment: "Accessibility text preceding a list of topics (i.e. Android, Cloud)"
    )

    let topics = viewModel.topics
    var topicsDescription = ""
    for index in 0 ..< topics.count {
      topicsDescription += topics[index].name
      if index == topics.count - 1 {
        topicsDescription += "."
      } else {
        topicsDescription += ", "
      }
    }

    let accessibilityDescription = viewModel.title + "\n" +
        viewModel.formattedDateInterval + "\n" +
        viewModel.location + "\n" +
        tagLabel + "\n" +
        topicsDescription

    accessibilityView.translatesAutoresizingMaskIntoConstraints = false
    accessibilityView.isAccessibilityElement = true
    accessibilityView.accessibilityLabel = accessibilityDescription
    contentView.addSubview(accessibilityView)
  }

  private func removeAccessibilityOverlay() {
    accessibilityView.removeFromSuperview()
    titleLabel.isAccessibilityElement = true
    timeAndLocationLabel.isAccessibilityElement = true
    tagContainer.enableAccessibilitySelect()
  }

}

// MARK: - Dynamic type

extension ScheduleViewCollectionViewCell {

  private func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc private func dynamicTypeTextSizeDidChange(_ sender: Any) {
    titleLabel.font = titleLabelFont
    timeAndLocationLabel.font = timeAndLocationLabelFont
    contentView.setNeedsLayout()
  }

}
