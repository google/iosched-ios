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

import MaterialComponents

/// Displays a single upcoming item. Not to be confused with
/// UpcomingItemsCollectionViewCell, which displays all upcoming items.
public class UpcomingItemCollectionViewCell: MDCCollectionViewCell {

  private static let timeFormatter: DateFormatter = {
    let formatter = TimeZoneAwareDateFormatter()
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

  static let cellSize = CGSize(width: 156, height: 156)

  private var session: Session?

  public override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(timeLabel)
    contentView.addSubview(starIconView)
    contentView.addSubview(reservationIconView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(locationLabel)

    setupConstraints()

    contentView.clipsToBounds = true
    contentView.layer.cornerRadius = 8
    contentView.layer.borderColor = UIColor(hex: 0xdadce0).cgColor
    contentView.layer.borderWidth = 1
  }

  private lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.preferredFont(forTextStyle: .subheadline)
    label.enableAdjustFontForContentSizeCategory()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(r: 60, g: 64, b: 67)
    return label
  }()

  private lazy var starIconView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.image = UIImage(named: "ic_session_bookmarked")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private lazy var reservationIconView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.image = UIImage(named: "ic_session_reserved")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.preferredFont(forTextStyle: .body)
    label.enableAdjustFontForContentSizeCategory()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(r: 32, g: 33, b: 36)
    return label
  }()

  private lazy var locationLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.preferredFont(forTextStyle: .subheadline)
    label.enableAdjustFontForContentSizeCategory()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(r: 95, g: 99, b: 104)
    return label
  }()

  public func populate(session: Session, isReserved: Bool, isBookmarked: Bool) {
    self.session = session
    let timeString =
        UpcomingItemCollectionViewCell.timeFormatter.string(from: session.startTimestamp)
    timeLabel.text = timeString
    titleLabel.text = session.title
    locationLabel.text = session.roomName

    if isReserved {
      starIconView.isHidden = true
      reservationIconView.isHidden = false
    } else if isBookmarked {
      starIconView.isHidden = false
      reservationIconView.isHidden = true
    } else {
      starIconView.isHidden = true
      reservationIconView.isHidden = true
    }
  }

  public override var intrinsicContentSize: CGSize {
    return UpcomingItemCollectionViewCell.cellSize
  }

  // MARK: - UIAccessibility

  private static let dateIntervalFormatter: DateIntervalFormatter = {
    let formatter = DateIntervalFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

  public override var isAccessibilityElement: Bool {
    get { return true }
    set {}
  }

  public override var accessibilityLabel: String? {
    set {}
    get {
      guard let session = session else { return nil }
      let formattedDateInterval = UpcomingItemCollectionViewCell.dateIntervalFormatter.string(
        from: session.startTimestamp,
        to: session.endTimestamp
      )

      let accessibilityDescription = session.title + "\n" +
        formattedDateInterval + "\n" +
        session.roomName

      return accessibilityDescription
    }
  }

  public override var accessibilityHint: String? {
    set {}
    get {
      return NSLocalizedString("Double-tap to view event details.",
                               comment: "Accessibility hint for upcoming items elements.")
    }
  }

  // MARK: - Constraints

  // swiftlint:disable function_body_length
  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: timeLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .top,
                         multiplier: 1,
                         constant: 12),
      NSLayoutConstraint(item: timeLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: starIconView,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: starIconView,
                         attribute: .centerY,
                         relatedBy: .equal,
                         toItem: timeLabel,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: starIconView,
                         attribute: .width,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 18),
      NSLayoutConstraint(item: starIconView,
                         attribute: .height,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 18),
      NSLayoutConstraint(item: reservationIconView,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: reservationIconView,
                         attribute: .centerY,
                         relatedBy: .equal,
                         toItem: timeLabel,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: reservationIconView,
                         attribute: .width,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 18),
      NSLayoutConstraint(item: reservationIconView,
                         attribute: .height,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 18),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: timeLabel,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .bottom,
                         relatedBy: .lessThanOrEqual,
                         toItem: locationLabel,
                         attribute: .top,
                         multiplier: 1,
                         constant: -8),
      NSLayoutConstraint(item: locationLabel,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -12),
      NSLayoutConstraint(item: locationLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: locationLabel,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16)
    ]

    titleLabel.setContentHuggingPriority(.required, for: .vertical)

    [timeLabel, locationLabel].forEach {
      $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
      $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    contentView.addConstraints(constraints)
  }
  // swiftlint:enable function_body_length

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

class EmptyItemsBackgroundView: UIView {

  var navigator: RootNavigator?

  let goToScheduleButton: MDCButton = {
    let button = MDCFlatButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    let title =
        NSLocalizedString("View sessions",
                          comment: "Tooltip to navigate to the Schedule screen")
    button.setTitle(title, for: .normal)
    button.isUppercaseTitle = false
    let titleColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    button.setTitleColor(titleColor, for: .normal)
    return button
  }()
  let label: UILabel = {
    let label = UILabel()
    label.font = ProductSans.regular.style(.body)
    label.text = NSLocalizedString("Your saved sessions will show up here.",
                                   comment: "Hint for empty upcoming sessions screen")
    label.numberOfLines = 2
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(r: 32, g: 33, b: 36)
    label.textAlignment = .center
    return label
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)

    layer.addSublayer(borderSublayer)
    addSubview(label)
    addSubview(goToScheduleButton)

    setupBorderSublayer()
    setupConstraints()
    // The target has to be added after super.init is called, so it can't be added in the
    // lazy initializer above.
    goToScheduleButton.addTarget(self,
                                 action: #selector(openScheduleScreen(_:)),
                                 for: .touchUpInside)
  }

  @objc func openScheduleScreen(_ sender: Any) {
    navigator?.navigateToSchedule()
  }

  private let borderSublayer = CALayer()

  private func setupBorderSublayer() {
    borderSublayer.cornerRadius = 8
    borderSublayer.borderColor = UIColor(hex: 0xdadce0).cgColor
    borderSublayer.borderWidth = 1
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let frame = layer.bounds.insetBy(dx: 16, dy: 16)
    borderSublayer.frame = frame
  }

  private func setupConstraints() {
    let constraints: [NSLayoutConstraint] = [
      NSLayoutConstraint(item: label,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: -8),
      NSLayoutConstraint(item: label,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 32),
      NSLayoutConstraint(item: label,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -32),
      NSLayoutConstraint(item: goToScheduleButton,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: label,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 8),
      NSLayoutConstraint(item: goToScheduleButton,
                         attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: goToScheduleButton,
                         attribute: .bottom,
                         relatedBy: .lessThanOrEqual,
                         toItem: self,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: goToScheduleButton,
                         attribute: .height,
                         relatedBy: .greaterThanOrEqual,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 48)
    ]

    label.setContentHuggingPriority(.required, for: .vertical)

    addConstraints(constraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
