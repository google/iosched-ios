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

class InfoViewController: BaseCollectionViewController {

  struct Constants {
    static let selectedTabColor = UIColor(red: 42 / 255, green: 42 / 255, blue: 42 / 255, alpha: 1)
    static let unselectedTabColor = UIColor(red: 74 / 255, green: 74 / 255, blue: 74 / 255, alpha: 1)
    static let tabBarTintColor = MDCPalette.indigo.accent200
    static let titleColor = UIColor(hex: "#202124")
    static let titleHeight: CGFloat = 24.0
    static let titleFont = UIFont(name: "Product Sans", size: Constants.titleHeight)!
  }

  let settingsViewModel: SettingsViewModel
  let travelDataSource = TravelRCDataSource()
  let androidThingsDataSource = AndroidThingsDataSource()

  init(settingsViewModel: SettingsViewModel) {
    self.settingsViewModel = settingsViewModel
    super.init(collectionViewLayout: MDCCollectionViewFlowLayout())

    settingsViewModel.presentingViewController = self
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) not supported for view controller of type \(InfoViewController.self)")
  }

  fileprivate var expandedTravelCells: [IndexPath: Bool] = [:]
  fileprivate var expandedFAQCells: [IndexPath: Bool] = [:]

  lazy var tabBar: MDCTabBar = self.setupTabBar()

  let eventItem = UITabBarItem(title: NSLocalizedString("Event", comment: "Event header"),
                               image: nil, tag: 0)
  let travelItem = UITabBarItem(title: NSLocalizedString("Transportation",
                                                         comment: "Transportation header"),
                                image: nil, tag: 1)
  let faqItem = UITabBarItem(title: NSLocalizedString("FAQ", comment: "FAQ header"),
                             image: nil, tag: 2)

  @objc override func setupViews() {
    super.setupViews()
    self.title = NSLocalizedString("Info", comment: "Title of the Info screen")
    setupCollectionView()
  }

  func setupTabBar() -> MDCTabBar {
    let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 48)
    let tabBar = MDCTabBar(frame: frame)

    tabBar.items = [
      self.eventItem, self.travelItem, self.faqItem
    ]
    tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
    tabBar.alignment = .justified
    tabBar.itemAppearance = .titles
    tabBar.delegate = self
    tabBar.tintColor = Constants.tabBarTintColor
    tabBar.selectedItemTintColor = Constants.selectedTabColor
    tabBar.unselectedItemTintColor = Constants.unselectedTabColor
    tabBar.titleTextTransform = .none
    return tabBar
  }

  func setupCollectionView() {
    // Would be nice to use self-sizing cells here, so we don't
    // have to duplicate cell size logic below in the layout delegate.
    collectionView?.register(WifiInfoCollectionViewCell.self,
                             forCellWithReuseIdentifier: WifiInfoCollectionViewCell.reuseIdentifier())
    collectionView?.register(EventInfoCollectionViewCell.self,
                             forCellWithReuseIdentifier: EventInfoCollectionViewCell.reuseIdentifier())
    collectionView?.register(InfoDetailCollectionViewCell.self,
                             forCellWithReuseIdentifier: InfoDetailCollectionViewCell.reuseIdentifier())
    collectionView?.register(CountdownCollectionViewCell.self,
                             forCellWithReuseIdentifier: CountdownCollectionViewCell.reuseIdentifier)
    collectionView?.register(AndroidThingsCollectionViewCell.self,
                             forCellWithReuseIdentifier: AndroidThingsCollectionViewCell.reuseIdentifier())
    styler.shouldAnimateCellsOnAppearance = false
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    travelDataSource.refreshConfig()

    // Prevent the bottom of the collection view's contents from being covered by the tab controller
    var insets = collectionView?.contentInset ?? UIEdgeInsets.zero
    insets.bottom = self.tabBarController?.tabBar.frame.size.height ?? 0
    collectionView?.contentInset = insets
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didChangePreferredContentSize(_:)),
                                           name: .UIContentSizeCategoryDidChange,
                                           object: nil)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }

  @objc override func setupAppBar() -> MDCAppBar {
    let appBar = super.setupAppBar()

    appBar.headerStackView.bottomBar = tabBar

    appBar.navigationBar.tintColor = Constants.selectedTabColor
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: Constants.titleColor,
      NSAttributedStringKey.font: Constants.titleFont
    ]
    appBar.navigationBar.titleTextAttributes = attributes

    let headerView = appBar.headerViewController.headerView
    headerView.minimumHeight = minHeaderHeight
    headerView.maximumHeight = maxHeaderHeight

    return appBar
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .`default`
  }

  override var minHeaderHeight: CGFloat {
    return super.minHeaderHeight - 60
  }

  override var maxHeaderHeight: CGFloat {
    return super.maxHeaderHeight
  }

// MARK: Analytics

  @objc override var screenName: String? {
    guard let item = tabBar.selectedItem else { return nil }

    switch item {
    case eventItem:
      return AnalyticsParameters.infoEvent
    case travelItem:
      return AnalyticsParameters.infoTravel
    case faqItem:
      return AnalyticsParameters.infoFAQ

    case _:
      return nil
    }
  }

  fileprivate func logSelectedItem(_ item: UITabBarItem) {
    guard let itemID = screenName else { return }
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.screen,
      AnalyticsParameterItemID: itemID
      ])
  }

}

// MARK: - MDCTabBarDelegate

extension InfoViewController: MDCTabBarDelegate {

  func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
    collectionView?.reloadData()
    logSelectedItem(item)

    if UIAccessibilityIsVoiceOverRunning() {
      collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
    }
  }

}

// MARK: - UICollectionViewDataSource

extension InfoViewController {

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let selectedItem = tabBar.selectedItem else { return 0 }

    switch selectedItem {

    case eventItem:
      return androidThingsDataSource.shouldDisplayAndroidThingsCell ? 7 : 6
    case travelItem:
      return InfoDetail.travelDetails.count + 1
    case faqItem:
      return InfoDetail.faqDetails.count + 1

    case _:
      return 0
    }

  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let selectedItem = tabBar.selectedItem ?? eventItem

    switch selectedItem {

    case eventItem:
      return cell(forEventCollectionView: collectionView, indexPath: indexPath)
    case travelItem:
      return cell(forTravelCollectionView: collectionView, indexPath: indexPath)
    case faqItem:
      return cell(forFAQCollectionView: collectionView, indexPath: indexPath)

    case _:
      fatalError()
    }
  }

  func cell(forEventCollectionView collectionView: UICollectionView,
            indexPath: IndexPath) -> UICollectionViewCell {
    // This is starting to get messy. It should be refactored to use multiple sections
    // so the indexpaths are cleaner.
    guard indexPath.row != 0 else {
      return collectionView.dequeueReusableCell(withReuseIdentifier: WifiInfoCollectionViewCell.reuseIdentifier(),
                                                for: indexPath)
    }
    if androidThingsDataSource.shouldDisplayAndroidThingsCell && indexPath.row == 1 {
      return collectionView.dequeueReusableCell(withReuseIdentifier: AndroidThingsCollectionViewCell.reuseIdentifier(),
                                                for: indexPath)
    }
    let offset = androidThingsDataSource.shouldDisplayAndroidThingsCell ? 2 : 1
    let range = androidThingsDataSource.shouldDisplayAndroidThingsCell ? 2...5 : 1...4
    switch indexPath.row {
    case range:
      let event = Event.events[indexPath.row - offset]
      // swiftlint:disable force_cast
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EventInfoCollectionViewCell.reuseIdentifier(),
                                                    for: indexPath) as! EventInfoCollectionViewCell
      // swiftlint:enable force_cast
      cell.summary = event.summary
      cell.title = event.title
      cell.titleIcon = event.icon
      cell.titleBackgroundColor = event.headerColor
      return cell

    case _:
      return collectionView.dequeueReusableCell(withReuseIdentifier: CountdownCollectionViewCell.reuseIdentifier,
                                                    for: indexPath)
    }
  }

  func cell(forTravelCollectionView collectionView: UICollectionView,
            indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InfoDetailCollectionViewCell.reuseIdentifier(),
                                                  for: indexPath) as! InfoDetailCollectionViewCell
    switch indexPath.row {

    case 0..<InfoDetail.travelDetails.count:
      let detail = travelDataSource.detail(forIndex: indexPath.row)
      let expanded = shouldExpandCell(atIndexPath: indexPath, forSelectedItem: tabBar.selectedItem)
      cell.populate(detail: detail, expanded: expanded)

    case InfoDetail.travelDetails.count:
      return collectionView.dequeueReusableCell(withReuseIdentifier: CountdownCollectionViewCell.reuseIdentifier,
                                                for: indexPath)

    case _:
      break
    }

    return cell
  }

  func cell(forFAQCollectionView collectionView: UICollectionView,
            indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InfoDetailCollectionViewCell.reuseIdentifier(),
                                                  for: indexPath) as! InfoDetailCollectionViewCell
    switch indexPath.row {

    case 0..<InfoDetail.faqDetails.count:
      let detail = InfoDetail.faqDetails[indexPath.row]
      let expanded = shouldExpandCell(atIndexPath: indexPath, forSelectedItem: tabBar.selectedItem)
      cell.populate(detail: detail, expanded: expanded)

    case InfoDetail.faqDetails.count:
      return collectionView.dequeueReusableCell(withReuseIdentifier: CountdownCollectionViewCell.reuseIdentifier,
                                                for: indexPath)

    case _:
      break
    }

    return cell
  }

}

// MARK: - UICollectionView Layout

extension InfoViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    let selectedItem = tabBar.selectedItem ?? eventItem

    switch selectedItem {

    case eventItem:
      return heightForEventCell(atIndexPath: indexPath)
    case travelItem:
      return heightForTravelCell(atIndexPath: indexPath)
    case faqItem:
      return heightForFAQCell(atIndexPath: indexPath)

    case _:
      fatalError()
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               shouldHideHeaderBackgroundForSection section: Int) -> Bool {
    return true
  }

  func heightForEventCell(atIndexPath indexPath: IndexPath) -> CGFloat {
    guard indexPath.row != 0 else {
      return WifiInfoCollectionViewCell.minimumHeightForContents
    }
    if androidThingsDataSource.shouldDisplayAndroidThingsCell {
      switch indexPath.row {
      case 1:
        return AndroidThingsCollectionViewCell.heightForContents(maxWidth: view.frame.size.width)
      case 2...5:
        let text = Event.events[indexPath.row - 2].summary
        return EventInfoCollectionViewCell.minimumHeight(summary: text,
                                                         maxWidth: view.frame.size.width)
      case _:
        break
      }
    } else {
      switch indexPath.row {
      case 1...4:
        let text = Event.events[indexPath.row - 1].summary
        return EventInfoCollectionViewCell.minimumHeight(summary: text,
                                                         maxWidth: view.frame.size.width)
      case _:
        break
      }
    }
    return CountdownCollectionViewCell.sizeForContents.height
  }

  func heightForTravelCell(atIndexPath indexPath: IndexPath) -> CGFloat {
    // Special case IO logo view, not expandable.
    if indexPath.row == InfoDetail.travelDetails.count {
      return CountdownCollectionViewCell.sizeForContents.height
    }
    if !shouldExpandCell(atIndexPath: indexPath, forSelectedItem: tabBar.selectedItem) { return 56 }

    switch indexPath.row {

    case 0..<InfoDetail.travelDetails.count:
      let detail = InfoDetail.travelDetails[indexPath.row]
      return InfoDetailCollectionViewCell.fullHeightForContents(detail: detail,
                                                                maxWidth: self.view.frame.size.width)

    case _:
      return 0
    }
  }

  func heightForFAQCell(atIndexPath indexPath: IndexPath) -> CGFloat {
    // Special case IO logo view, not expandable.
    if indexPath.row == InfoDetail.faqDetails.count {
      return CountdownCollectionViewCell.sizeForContents.height
    }
    if !shouldExpandCell(atIndexPath: indexPath, forSelectedItem: tabBar.selectedItem) { return 56 }

    switch indexPath.row {

    case 0..<InfoDetail.faqDetails.count:
      let detail = InfoDetail.faqDetails[indexPath.row]
      return InfoDetailCollectionViewCell.fullHeightForContents(detail: detail,
                                                                maxWidth: self.view.frame.size.width)

    case _:
      return 0
    }
  }

}

// MARK: - UICollectionViewDelegate

extension InfoViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               shouldSelectItemAt indexPath: IndexPath) -> Bool {
    if let _ = collectionView.cellForItem(at: indexPath) as? WifiInfoCollectionViewCell {
      // Copy wifi password to clipboard and show it in the UI somehow.
      UIPasteboard.general.string = WifiInfoCollectionViewCell.wifiPassword
      let message = MDCSnackbarMessage()
      message.text = NSLocalizedString("Copied I/O Wifi password to clipboard", comment: "Text to be displayed after tapping the cell to copy the wifi password to clipboard. Text will be read to visually-impaired users using VoiceOver accessibility")
      MDCSnackbarManager.show(message)
      return false
    }

    if let _ = collectionView.cellForItem(at: indexPath) as? AndroidThingsCollectionViewCell {
      UIApplication.shared.openURL(AndroidThingsCollectionViewCell.scavengerHuntURL)
      return false
    }

    guard let selected = tabBar.selectedItem else { return false }
    let expanded = toggleCell(atIndexPath: indexPath, forSelectedItem: selected)
    guard let cell = collectionView.cellForItem(at: indexPath)
      as? InfoDetailCollectionViewCell else { return false }

    collectionView.performBatchUpdates({
      if expanded {
        cell.expand()
      } else {
        cell.collapse()
      }
      collectionView.reloadItems(at: [indexPath])
    }) { (completed) in }

    return false
  }

}

// MARK: - Expandable Cells

extension InfoViewController {

  private func _shouldExpandCell(atIndexPath indexPath: IndexPath,
                                 forSelectedItem selectedItem: UIBarItem) -> Bool {
    switch selectedItem {

    case travelItem:
      return expandedTravelCells[indexPath] ?? false
    case faqItem:
      return expandedFAQCells[indexPath] ?? false

    case _: return false
    }
  }

  func shouldExpandCell(atIndexPath indexPath: IndexPath, forSelectedItem selectedItem: UIBarItem?) -> Bool {
    guard let selected = selectedItem else { return false }
    return _shouldExpandCell(atIndexPath: indexPath, forSelectedItem: selected)
  }

  func expandCell(atIndexPath indexPath: IndexPath, forSelectedItem selectedItem: UIBarItem) {
    switch selectedItem {

    case travelItem:
      expandedTravelCells[indexPath] = true
    case faqItem:
      expandedFAQCells[indexPath] = true

    case _: return
    }
  }

  func collapseCell(atIndexPath indexPath: IndexPath, forSelectedItem selectedItem: UIBarItem) {
    switch selectedItem {

    case travelItem:
      expandedTravelCells[indexPath] = nil
    case faqItem:
      expandedFAQCells[indexPath] = nil

    case _: return
    }
  }

  /// Returns the expanded state of the cell after the operation.
  /// True for expanded, false otherwise.
  func toggleCell(atIndexPath indexPath: IndexPath, forSelectedItem selectedItem: UIBarItem) -> Bool {
    switch selectedItem {

    case travelItem, faqItem:
      if shouldExpandCell(atIndexPath: indexPath, forSelectedItem: selectedItem) {
        collapseCell(atIndexPath: indexPath, forSelectedItem: selectedItem)
        return false
      } else {
        expandCell(atIndexPath: indexPath, forSelectedItem: selectedItem)
        return true
      }

    case _: return false
    }
  }
}

// MARK: Dynamic Type

extension InfoViewController {

  @objc func didChangePreferredContentSize(_ notification: Notification) {
    collectionView?.reloadData()
    collectionView?.setNeedsDisplay()
  }

}

// MARK: Navigation {

extension InfoViewController {

  func showEventInfo() {
    tabBar.selectedItem = eventItem
    collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
  }

}

