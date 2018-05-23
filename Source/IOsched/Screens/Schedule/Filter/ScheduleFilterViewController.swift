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

import Firebase
import MaterialComponents

typealias ScheduleFilterDoneCallback = () -> Void

class ScheduleFilterViewController: BaseCollectionViewController {

  fileprivate let viewModel: ScheduleFilterViewModel
  fileprivate let doneCallback: ScheduleFilterDoneCallback

  init(viewModel: ScheduleFilterViewModel, doneCallback: @escaping ScheduleFilterDoneCallback) {
    self.viewModel = viewModel
    self.doneCallback = doneCallback
    super.init(collectionViewLayout: MDCCollectionViewFlowLayout())
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

// MARK: - View setup

  fileprivate enum Constants {
    static let headerBackgroundColor = UIColor.white

    static let maxHeaderHeight: CGFloat = 100
    static let minHeaderHeight: CGFloat = 100

    static let textColor = UIColor(hex: "#424242")
    static let headerTextColor = UIColor(hex: "#424242")

    static let listItemBackgroundColor = UIColor.white

    static let title = NSLocalizedString("Filters", comment: "Title for schedule filters page")
    static let resetButtonTitle =
      NSLocalizedString("Reset", comment: "Button title for reset button on schedule filters page")
    static let doneButtonTitle =
      NSLocalizedString("Done", comment: "Button title for done button on schedule filters page")

    static func sectionHeaderFont() -> UIFont {
      return ProductSans.regular.style(.callout)
    }
  }

  @objc override func setupViews() {
    super.setupViews()

    title = Constants.title
    setupCollectionView()

    navigationItem.leftBarButtonItem = setupResetButton()
    navigationItem.rightBarButtonItem = setupDoneButton()
  }

  @objc override var minHeaderHeight: CGFloat {
    return Constants.minHeaderHeight
  }

  @objc override var maxHeaderHeight: CGFloat {
    return Constants.maxHeaderHeight
  }

  @objc override var headerBackgroundColor: UIColor {
    return Constants.headerBackgroundColor
  }

  func setupCollectionView() {
    collectionView?.register(MDCCollectionViewTextCell.self,
                             forCellWithReuseIdentifier: MDCCollectionViewTextCell.reuseIdentifier())
    collectionView?.register(ScheduleFilterCollectionViewCell.self,
                             forCellWithReuseIdentifier: ScheduleFilterCollectionViewCell.reuseIdentifier())
    collectionView?.register(MDCCollectionViewTextCell.self,
                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
    styler.cellStyle = .default
    styler.shouldAnimateCellsOnAppearance = false
  }

  func setupResetButton() -> UIBarButtonItem {
    let button = UIBarButtonItem(title: Constants.resetButtonTitle,
                                 style: .plain,
                                 target: self,
                                 action: #selector(resetAction))
    button.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Constants.headerTextColor],
                                  for: .normal)
    return button
  }

  func setupDoneButton() -> UIBarButtonItem {
    let button = UIBarButtonItem(title: Constants.doneButtonTitle,
                                 style: .done,
                                 target: self,
                                 action: #selector(doneAction))
    button.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Constants.headerTextColor],
                                  for: .normal)
    return button
  }
}

// MARK: - Actions
extension ScheduleFilterViewController {
  @objc func resetAction() {
    viewModel.reset()
    self.collectionView?.reloadData()
  }

  @objc func doneAction() {
    doneCallback()
  }
}

// MARK: - MDCCollectionViewStylingDelegate

extension ScheduleFilterViewController {
  override func collectionView(_ collectionView: UICollectionView,
                               cellBackgroundColorAt indexPath: IndexPath) -> UIColor {
    return Constants.listItemBackgroundColor
  }
}

// MARK: - UICollectionView Layout
extension ScheduleFilterViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    let section = viewModel.filterSections[section]
    if section.name == nil {
      return CGSize.zero
    } else {
      return CGSize(width: collectionView.bounds.size.width, height: MDCCellDefaultOneLineHeight)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, shouldHideHeaderBackgroundForSection section: Int) -> Bool {
    return true
  }
}

// MARK: - UICollectionViewDataSource

extension ScheduleFilterViewController {

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return viewModel.filterSections.count
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let section = viewModel.filterSections[section]
    return section.items.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let section = viewModel.filterSections[indexPath.section]
    let item = section.items[indexPath.item]
    let itemColor = item.color
    if itemColor == nil {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MDCCollectionViewTextCell.reuseIdentifier(),
                                                    for: indexPath)
      if let normalCell = cell as? MDCCollectionViewTextCell {
        normalCell.accessoryType = item.selected ? .checkmark : .none
        if let textLabel = normalCell.textLabel {
          textLabel.textColor = Constants.textColor
          textLabel.text = item.name
          textLabel.font = UIFont.preferredFont(forTextStyle: .callout)
          textLabel.enableAdjustFontForContentSizeCategory()
          // Add style for topics.
        }
      }
      return cell
    } else {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScheduleFilterCollectionViewCell.reuseIdentifier(),
                                                    for: indexPath)
      if let topicCell = cell as? ScheduleFilterCollectionViewCell {
        topicCell.accessoryType = item.selected ? .checkmark : .none
        topicCell.viewModel = item
      }
      return cell
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    let section = viewModel.filterSections[indexPath.section]
    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                               withReuseIdentifier: MDCCollectionViewTextCell.reuseIdentifier(),
                                                               for: indexPath)

    if let sectionHeader = view as? MDCCollectionViewTextCell {
      if kind == UICollectionView.elementKindSectionHeader {
        sectionHeader.shouldHideSeparator = true
        if let textLabel = sectionHeader.textLabel {
          textLabel.text = section.name
          textLabel.font = Constants.sectionHeaderFont()
          textLabel.textColor = Constants.textColor
        }
      }
      return sectionHeader
    }
    return view
  }

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    let section = viewModel.filterSections[indexPath.section]
    let mapItem = section.items[indexPath.item]
    mapItem.selected = !mapItem.selected
    self.collectionView?.reloadItems(at: [indexPath])

    if mapItem.selected {
      logSelectedFilter(withName: mapItem.name)
    }
  }
}

// MARK: - Analytics

extension ScheduleFilterViewController {

  fileprivate func logSelectedFilter(withName name: String) {
    let itemID = AnalyticsParameters.itemID(forSelectedFilter: name)
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.uiEvent,
      AnalyticsParameterItemID: itemID,
      AnalyticsParameters.uiAction: AnalyticsParameters.filterUsed
    ])
  }

}

class ScheduleFilterCollectionViewCell: MDCCollectionViewCell {

  private lazy var tagButton: TagButton = self.setupTagButton()

  var viewModel: ScheduleFilterItemViewModel? {
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

  private func setupTagButton() -> TagButton {
    let tagButton = TagButton()
    tagButton.translatesAutoresizingMaskIntoConstraints = false
    tagButton.setElevation(ShadowElevation(rawValue: 0), for: UIControl.State())
    tagButton.isUppercaseTitle = false
    tagButton.isAccessibilityElement = false
    tagButton.isUserInteractionEnabled = false
    return tagButton
  }

  private func setupViews() {
    contentView.addSubview(tagButton)

    let views: [String: UIView] = ["tag": tagButton]

    var constraints =
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[tag]",
                                     options: [],
                                     metrics: nil,
                                     views: views)
    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[tag(24)]",
                                     options: [],
                                     metrics: nil,
                                     views: views)

    NSLayoutConstraint.activate(constraints)
  }

  private func updateFromViewModel() {
    if let viewModel = viewModel {
      tagButton.setTitle(viewModel.name, for: .normal)
      let color = viewModel.color.map(UIColor.init(hex:))
      tagButton.setBackgroundColor(color, for: .normal)

      invalidateIntrinsicContentSize()
      setNeedsLayout()
    }
  }
}
