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

class MapVariantSelectorView: UIView {

  var selectedVariant: MapViewController.MapVariant {
    set {
      dataSource.selectedVariant = newValue
    }
    get {
      return dataSource.selectedVariant
    }
  }

  var buttonPressedCallback: ((MapViewController.MapVariant) -> Void)? {
    set {
      dataSource.buttonPressedCallback = newValue
    }
    get {
      return dataSource.buttonPressedCallback
    }
  }

  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 0
    let view = UICollectionView(frame: frame, collectionViewLayout: layout)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.dataSource = dataSource
    view.delegate = dataSource
    view.isScrollEnabled = false
    view.backgroundColor = .clear
    view.reloadData()
    view.register(MapVariantCollectionViewCell.self,
                  forCellWithReuseIdentifier: MapVariantCollectionViewCell.reuseIdentifier())
    return view
  }()

  private lazy var collectionViewWidthConstraint = NSLayoutConstraint(item: collectionView,
                                                                      attribute: .width,
                                                                      relatedBy: .equal,
                                                                      toItem: nil,
                                                                      attribute: .notAnAttribute,
                                                                      multiplier: 1,
                                                                      constant: 0)

  private lazy var dataSource = MapVariantCollectionViewDataSource()

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    addSubview(collectionView)
    setupConstraints()

    collectionViewWidthConstraint.constant = dataSource.maxSizeForContents().width
    addConstraint(collectionViewWidthConstraint)
    backgroundColor = .white

    layer.cornerRadius = 6
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.2
    layer.shadowRadius = 10
    layer.masksToBounds = false
  }

  override var intrinsicContentSize: CGSize {
    return dataSource.maxSizeForContents()
  }

  override func layoutSubviews() {
    collectionViewWidthConstraint.constant = dataSource.maxSizeForContents().width
    super.layoutSubviews()
  }

  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: collectionView,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .top,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: collectionView,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: collectionView,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .right,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: collectionView,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 0)
    ]

    addConstraints(constraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

private class MapVariantCollectionViewDataSource: NSObject,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  var selectedVariant: MapViewController.MapVariant = .day
  var buttonPressedCallback: ((MapViewController.MapVariant) -> Void)?

  private func titleIcon(for variant: MapViewController.MapVariant) -> (title: String, icon: UIImage?) {
    let title: String, icon: UIImage?
    switch variant {
    case .day:
      title = NSLocalizedString("Daytime",
                                comment: "Button label for showing the map during daytime")
      icon = UIImage(named: "map_layer_day")

    case .night:
      title = NSLocalizedString("After Dark",
                                comment: "Button label for showing the map during nighttime")
      icon = UIImage(named: "map_layer_night")

    case .concert:
      title = NSLocalizedString("Concert",
                                comment: "Button label for showing the map during the concert")
      icon = UIImage(named: "map_layer_concert")
    }
    return (title: title, icon: icon)
  }

  func maxSizeForContents() -> CGSize {
    // The width of the longest cell. Brittle, but all cell contents are constant so it's ok.
    let boundingSize = CGSize(width: CGFloat.greatestFiniteMagnitude,
                              height: CGFloat.greatestFiniteMagnitude)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.preferredFont(forTextStyle: .callout)
    ]
    let options: NSStringDrawingOptions = [
      .usesFontLeading, .usesDeviceMetrics, .usesLineFragmentOrigin
    ]

    // All sizes must be calculated and compared, since different titles may be
    // different sizes in different languages.
    let daySize = titleIcon(for: .day).title.boundingRect(with: boundingSize,
                                                          options: options,
                                                          attributes: attributes,
                                                          context: nil)
    let nightSize = titleIcon(for: .night).title.boundingRect(with: boundingSize,
                                                              options: options,
                                                              attributes: attributes,
                                                              context: nil)
    let concertSize = titleIcon(for: .concert).title.boundingRect(with: boundingSize,
                                                                  options: options,
                                                                  attributes: attributes,
                                                                  context: nil)

    let maxWidth = max(daySize.width, nightSize.width, concertSize.width)
    let totalWidth = maxWidth + 70

    let height = UIFont.preferredFont(forTextStyle: .callout).lineHeight * 3 + 72
    return CGSize(width: totalWidth, height: height)
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return 3
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: MapVariantCollectionViewCell.reuseIdentifier(),
      for: indexPath
    ) as! MapVariantCollectionViewCell

    switch indexPath.item {
    case 0:
      let (title, icon) = titleIcon(for: .day)
      cell.populate(title: title, icon: icon, selected: selectedVariant == .day)
    case 1:
      let (title, icon) = titleIcon(for: .night)
      cell.populate(title: title, icon: icon, selected: selectedVariant == .night)
    case 2:
      let (title, icon) = titleIcon(for: .concert)
      cell.populate(title: title, icon: icon, selected: selectedVariant == .concert)
    case _:
      break
    }

    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let height = MapVariantCollectionViewCell.heightForContents()
    let width = collectionView.frame.size.width
    return CGSize(width: width, height: height)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    switch indexPath.item {
    case 0:
      buttonPressedCallback?(.day)
      selectedVariant = .day
    case 1:
      buttonPressedCallback?(.night)
      selectedVariant = .night
    case 2:
      buttonPressedCallback?(.concert)
      selectedVariant = .concert

    case _:
      break
    }
    collectionView.reloadData()
  }

}

private class MapVariantCollectionViewCell: MDCCollectionViewCell {

  private let unselectedColor = UIColor(hex: 0x323336)
  private let selectedColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)

  private let titleLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 1
    label.font = UIFont.preferredFont(forTextStyle: .callout)
    label.textColor = UIColor(hex: 0x323336)
    label.enableAdjustFontForContentSizeCategory()
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private let iconView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(titleLabel)
    contentView.addSubview(iconView)
    setupConstraints()
  }

  static func heightForContents() -> CGFloat {
    return UIFont.preferredFont(forTextStyle: .callout).lineHeight + 24
  }

  func populate(title: String, icon: UIImage?, selected: Bool) {
    titleLabel.text = title

    if selected {
      titleLabel.textColor = selectedColor
      let templatableIcon = icon?.withRenderingMode(.alwaysTemplate)
      iconView.image = templatableIcon
      iconView.tintColor = selectedColor
    } else {
      titleLabel.textColor = unselectedColor
      iconView.image = icon
      iconView.tintColor = nil
    }
  }

  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: iconView,
                         attribute: .centerY,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: iconView,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: iconView,
                         attribute: .width,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 20),
      NSLayoutConstraint(item: iconView,
                         attribute: .height,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 20),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: iconView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: 14),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .top,
                         multiplier: 1,
                         constant: 12),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -12)
    ]
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

    contentView.addConstraints(constraints)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
