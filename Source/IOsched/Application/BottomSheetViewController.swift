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

public protocol BottomSheetViewControllerDelegate: NSObjectProtocol {

  func bottomSheetController(_ controller: BottomSheetViewController,
                             didSelect selectedViewController: UIViewController)

}

public class BottomSheetViewController: MDCCollectionViewController {

  private let drawerItems: [UIViewController]
  public weak var delegate: BottomSheetViewControllerDelegate?

  public init(drawerItems: [UIViewController]) {
    self.drawerItems = drawerItems
    let layout = MDCCollectionViewFlowLayout()
    layout.estimatedItemSize = CGSize(width: 375, height: 48)
    super.init(collectionViewLayout: MDCCollectionViewFlowLayout())
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.register(
      BottomSheetCollectionViewCell.self,
      forCellWithReuseIdentifier: BottomSheetCollectionViewCell.reuseIdentifier()
    )
    collectionView.backgroundColor = .white
    collectionView.isScrollEnabled = false
    collectionView.layer.cornerRadius = 8
    collectionView.clipsToBounds = true
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionView.reloadData()

    registerForDynamicTypeUpdates()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - UICollectionViewDataSource

  public override func collectionView(_ collectionView: UICollectionView,
                                      numberOfItemsInSection section: Int) -> Int {
    return drawerItems.count
  }

  public override func collectionView(_ collectionView: UICollectionView,
                                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: BottomSheetCollectionViewCell.reuseIdentifier(),
      for: indexPath
    ) as! BottomSheetCollectionViewCell
    cell.populate(item: drawerItems[indexPath.item])
    return cell
  }

  public override func collectionView(_ collectionView: UICollectionView,
                                      shouldHideItemSeparatorAt indexPath: IndexPath) -> Bool {
    return true
  }

  // MARK: - UICollectionViewDelegate

  public override func collectionView(_ collectionView: UICollectionView,
                                      didSelectItemAt indexPath: IndexPath) {
    super.collectionView(collectionView, didSelectItemAt: indexPath)
    collectionView.deselectItem(at: indexPath, animated: true)
    let controller = drawerItems[indexPath.item]
    delegate?.bottomSheetController(self, didSelect: controller)
  }

  // MARK: - Layout

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    collectionView?.collectionViewLayout.invalidateLayout()
    collectionView?.reloadData()
  }

}

public class BottomSheetCollectionViewCell: MDCCollectionViewCell {

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    return imageView
  }()
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = ProductSans.regular.style(.body)
    label.textColor = UIColor(r: 60, g: 64, b: 67)
    return label
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(imageView)
    contentView.addSubview(titleLabel)

    setupConstraints()
    shouldHideSeparator = true
  }

  public func populate(item: UIViewController) {
    imageView.image = item.tabBarItem?.image
    titleLabel.text = item.tabBarItem?.title
    titleLabel.font = ProductSans.regular.style(.body)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override var intrinsicContentSize: CGSize {
    let imageViewSize = CGSize(width: 60, height: 48)
    let textSize = titleLabel.intrinsicContentSize
    let maxHeight = max(imageViewSize.height, textSize.height + 32)
    let totalWidth = imageViewSize.width + textSize.width + 16
    return CGSize(width: totalWidth, height: maxHeight)
  }

  public override var isAccessibilityElement: Bool {
    get { return true }
    set {}
  }

  public override var accessibilityLabel: String? {
    get { return titleLabel.text }
    set {}
  }

  public override var accessibilityHint: String? {
    set {}
    get {
      guard let screenName = titleLabel.text else { return nil }
      return NSLocalizedString("Double-tap to open the \(screenName) screen.",
        comment: "Localized accessibility hint for buttons in the bottom sheet navigation view.")
    }
  }

  private func setupConstraints() {
    let constraints = [
      // Image view
      NSLayoutConstraint(item: imageView,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .left,
                         multiplier: 1,
                         constant: 24),
      NSLayoutConstraint(item: imageView,
                         attribute: .centerY,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: imageView,
                         attribute: .width,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 20),
      NSLayoutConstraint(item: imageView,
                         attribute: .height,
                         relatedBy: .equal,
                         toItem: nil,
                         attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 20),
      // Title label
      NSLayoutConstraint(item: titleLabel,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: imageView,
                         attribute: .right,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .right,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .centerY,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .centerY,
                         multiplier: 1,
                         constant: 0)
    ]
    imageView.setContentHuggingPriority(.required, for: .horizontal)
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

    contentView.addConstraints(constraints)
  }

}

enum ProductSans: String {

  case regular = "ProductSans-Regular"

  func style(_ textStyle: UIFont.TextStyle, sizeOffset: CGFloat = 0) -> UIFont {
    let size = UIFont.preferredFont(forTextStyle: textStyle).pointSize + sizeOffset
    return UIFont(name: rawValue, size: size)!
  }

}
