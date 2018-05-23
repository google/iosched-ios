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

protocol MapFilterViewControllerDelegate: class {
  func viewControllerDidFinish()
}

class MapFilterViewController: BaseCollectionViewController {

  fileprivate var viewModel: MapViewModel
  fileprivate weak var delegate: MapFilterViewControllerDelegate?

  init(viewModel: MapViewModel, delegate: MapFilterViewControllerDelegate) {
    self.viewModel = viewModel
    self.delegate = delegate
    super.init(collectionViewLayout: MDCCollectionViewFlowLayout())
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

// MARK: - View setup

  fileprivate enum Constants {
    static let headerBackgroundColor = MDCPalette.teal.accent400
    static let maxHeaderHeight: CGFloat = 76
    static let minHeaderHeight: CGFloat = 76
    static let textColor = MDCPalette.grey.tint800
    static let sectionHeaderBackgroundColor = MDCPalette.grey.tint50
    static let listItemBackgroundColor = UIColor.white
    static let title = NSLocalizedString("Filters", comment: "Title for map filters page")
    static let resetButtonTitle =
        NSLocalizedString("Reset", comment: "Button title for reset button")
    static let doneButtonTitle =
        NSLocalizedString("Done", comment: "Button title for done button")
    static let moreImage = UIImage(named: "ic_expand_more")
    static let lessImage = UIImage(named: "ic_expand_less")
  }

  @objc override func setupViews() {
    super.setupViews()

    self.title = Constants.title
    self.setupCollectionView()

    self.navigationItem.leftBarButtonItem = setupResetButton()
    self.navigationItem.rightBarButtonItem = setupDoneButton()
  }

  @objc override var minHeaderHeight: CGFloat {
    return Constants.minHeaderHeight
  }

  @objc override var maxHeaderHeight: CGFloat {
    return Constants.maxHeaderHeight
  }

  @objc override var headerBackgroundColor: UIColor {
    return Constants.headerBackgroundColor!
  }

  @objc override func setupAppBar() -> MDCAppBar {
    let appBar = super.setupAppBar()

    let headerView = appBar.headerViewController.headerView
    headerView.backgroundColor = Constants.headerBackgroundColor

    appBar.navigationBar.tintColor = Constants.textColor
    appBar.navigationBar.titleTextAttributes =
        [ NSAttributedStringKey.foregroundColor: Constants.textColor ]

    return appBar
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    // Ensure that our status bar is black.
    return .default
  }

  func setupCollectionView() {
    collectionView?.register(MDCCollectionViewTextCell.self,
                             forCellWithReuseIdentifier: MDCCollectionViewTextCell.reuseIdentifier())
    collectionView?.register(ExpandableSectionHeaderTextCell.self,
                             forCellWithReuseIdentifier: ExpandableSectionHeaderTextCell.reuseIdentifier())
    styler.cellStyle = .default
    styler.shouldAnimateCellsOnAppearance = false
  }

  func setupResetButton() -> UIBarButtonItem {
    let button = UIBarButtonItem(title: Constants.resetButtonTitle,
                                 style: .plain,
                                 target: self,
                                 action: #selector(resetAction))
    button.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: Constants.textColor],
                                  for: .normal)
    return button
  }

  func setupDoneButton() -> UIBarButtonItem {
    let button = UIBarButtonItem(title: Constants.doneButtonTitle,
                                 style: .done,
                                 target: self,
                                 action: #selector(doneAction))
    button.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: Constants.textColor],
                                  for: .normal)
    return button
  }
}

// MARK: - Actions
extension MapFilterViewController {
  @objc func resetAction() {
    for section in viewModel.filterSections {
      for mapItem in section.items {
        mapItem.selected = false
      }
    }
    self.collectionView?.reloadData()
  }

  @objc func doneAction() {
    guard let delegate = delegate else {
      return
    }
    delegate.viewControllerDidFinish()
  }
}

// MARK: - MDCCollectionViewStylingDelegate

extension MapFilterViewController {
  override func collectionView(_ collectionView: UICollectionView,
                               cellBackgroundColorAt indexPath: IndexPath) -> UIColor {
    if indexPath.item == 0 {
      return Constants.sectionHeaderBackgroundColor
    }
    return Constants.listItemBackgroundColor
  }
}

// MARK: - UICollectionViewDataSource

extension MapFilterViewController {

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return viewModel.filterSections.count
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let section = viewModel.filterSections[section]
    if section.expanded {
      return section.items.count + 1
    } else {
      return 1
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let section = viewModel.filterSections[indexPath.section]
    if indexPath.item == 0 {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExpandableSectionHeaderTextCell.reuseIdentifier(),
                                                    for: indexPath)
      if let headerCell = cell as? ExpandableSectionHeaderTextCell {
        headerCell.expanded = section.expanded
        if let textLabel = headerCell.textLabel {
          textLabel.textColor = Constants.textColor
          textLabel.text = section.name
        }
      }
      return cell

    } else {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MDCCollectionViewTextCell.reuseIdentifier(),
                                                    for: indexPath)
      if let normalCell = cell as? MDCCollectionViewTextCell {
        let mapItem = section.items[indexPath.item - 1]
        normalCell.accessoryType = mapItem.selected ? .checkmark : .none
        if let textLabel = normalCell.textLabel {
          textLabel.textColor = Constants.textColor
          textLabel.text = mapItem.title
        }
      }
      return cell
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    let section = viewModel.filterSections[indexPath.section]
    if indexPath.item == 0 {
      section.expanded = !section.expanded
      self.collectionView?.reloadSections(IndexSet(integer: indexPath.section))
    } else {
      let mapItem = section.items[indexPath.item - 1]
      mapItem.selected = !mapItem.selected
      self.collectionView?.reloadItems(at: [indexPath])
    }
  }
}
