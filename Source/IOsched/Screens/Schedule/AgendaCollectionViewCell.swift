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

class AgendaCollectionViewCell: MDCCollectionViewCell {

  public static var cellHeight: CGFloat {
    return 72
  }

  private static let dateIntervalFormatter: DateIntervalFormatter = {
    let formatter = DateIntervalFormatter()
    formatter.timeZone = TimeZone.userTimeZone()
    formatter.dateTemplate = "hh:mm"
    return formatter
  }()

  private lazy var titleLabel: UILabel = self.setupTitleLabel()
  private lazy var iconView: UIImageView = self.setupIconView()
  private lazy var timeLabel: UILabel = self.setupTimeLabel()
  private lazy var colorView: UIView = self.setupColorView()

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    isUserInteractionEnabled = false

    contentView.addSubview(colorView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(timeLabel)
    contentView.addSubview(iconView)

    contentView.addConstraints(iconViewConstraints)
    contentView.addConstraints(timeLabelConstraints)
    contentView.addConstraints(titleLabelConstraints)
    contentView.addConstraints(colorViewConstraints)
  }

  private func setupTitleLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hex: "#202124")
    label.numberOfLines = 1
    label.font = UIFont.preferredFont(forTextStyle: .subheadline)
    return label
  }

  private func setupTimeLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hex: "#202124")
    label.numberOfLines = 1
    label.font = UIFont.preferredFont(forTextStyle: .caption1)
    return label
  }

  private func setupIconView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    return imageView
  }

  private func setupColorView() -> UIView {
    let view = UIView()
    view.layer.cornerRadius = 3
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  private var iconViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: iconView, attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .leading,
                         multiplier: 1, constant: 16),
      NSLayoutConstraint(item: iconView, attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .top,
                         multiplier: 1, constant: 16),
      NSLayoutConstraint(item: iconView, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: 28),
      NSLayoutConstraint(item: iconView, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: 28),
    ]
  }

  private var titleLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: titleLabel, attribute: .leading,
                         relatedBy: .equal,
                         toItem: iconView, attribute: .trailing,
                         multiplier: 1, constant: 20),
      NSLayoutConstraint(item: titleLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .top,
                         multiplier: 1, constant: 10),
    ]
  }

  private var timeLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: timeLabel, attribute: .leading,
                         relatedBy: .equal,
                         toItem: iconView, attribute: .trailing,
                         multiplier: 1, constant: 20),
      NSLayoutConstraint(item: timeLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: titleLabel, attribute: .bottom,
                         multiplier: 1, constant: 6),
    ]
  }

  private var colorViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: colorView, attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .top,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: colorView, attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .leading,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: colorView, attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .trailing,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: colorView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .bottom,
                         multiplier: 1, constant: -12),
    ]
  }

  public func populate(with agendaItem: AgendaItem) {
    titleLabel.text = agendaItem.title
    timeLabel.text =
        AgendaCollectionViewCell.dateIntervalFormatter.string(from: agendaItem.startDate,
                                                              to: agendaItem.endDate)
    colorView.backgroundColor = agendaItem.backgroundColor
    titleLabel.textColor = agendaItem.textColor
    timeLabel.textColor = agendaItem.textColor

    iconView.image = agendaItem.image
  }

}
