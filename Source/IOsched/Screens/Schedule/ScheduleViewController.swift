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

import AlamofireImage
import Firebase
import Foundation
import GoogleSignIn
import MaterialComponents

class ScheduleViewController: BaseCollectionViewController {

  fileprivate enum TooltipsConstants {
    static let titleColor = "#424242"
  }

  private let agendaDataSource = AgendaDataSource()
  private lazy var filterBar: FilterBar = self.setupFilterBar()
  private lazy var filterButton: MDCFloatingButton = self.setupFilterFloatingButton()
  private lazy var switchBarButton: MDCFlatButton = MDCFlatButton()
  private var showBookmarkedAndReserved: Bool = false
  private lazy var tabBar: MDCTabBar = self.setupTabBar()
  private lazy var emptyMyIOView = ScheduleCollectionEmptyView()

  var selectedTabIndex = 0 {
    didSet {
      scheduleViewModel.collectionView(collectionView, scrollToDay: selectedTabIndex)
      updateBackgroundView()
      logSelectedDay()
    }
  }

  func selectDay(day: Int) {
    if day < tabBar.items.count {
      tabBar.selectedItem = tabBar.items[day]
      selectedTabIndex = day
    }
  }

  let scheduleViewModel: ScheduleDisplayableViewModel

  init(viewModel: ScheduleDisplayableViewModel,
       searchViewController: SearchCollectionViewController) {
    self.scheduleViewModel = viewModel
    self.searchViewController = searchViewController
    let layout = SideHeaderCollectionViewLayout()
    layout.headerReferenceSize = CGSize(width: 60, height: 8)
    layout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.size.width, height: 120)
    super.init(collectionViewLayout: SideHeaderCollectionViewLayout())
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.backgroundColor = .white
    collectionView?.dataSource = scheduleViewModel
    registerForViewUpdates()
    registerForDynamicTypeUpdates()
    refreshContent()
    collectionView.showsVerticalScrollIndicator = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    logSelectedDay()
  }

  func registerForViewUpdates() {
    scheduleViewModel.onUpdate { [weak self] indexPath in
      self?.performViewUpdate(indexPath: indexPath)
    }
  }

  func performViewUpdate(indexPath: IndexPath?) {
    if indexPath != nil {
      self.collectionView?.reloadData()
    }
    else {
      self.refreshUI()
    }
  }

  private func updateTabBarItems() {

    let items = scheduleViewModel.conferenceDays.map {
      UITabBarItem(title: $0.dayString, image: nil, tag: 0)
    }
    tabBar.items = items
  }

  func refreshUI() {
    var selectedIndex = 0
    if let selectedItem = tabBar.selectedItem {
      selectedIndex = tabBar.items.index(of: selectedItem) ?? 0
    }

    if scheduleViewModel.conferenceDays.count > 0 {
      updateTabBarItems()
      tabBar.selectedItem = tabBar.items[selectedIndex]
    }

    updateBackgroundView()
    self.collectionView?.reloadData()

    if let filterString = scheduleViewModel.wrappedModel.filterViewModel.filterString {
      filterBar.isFilterVisible = true
      filterBar.filterText = filterString
    } else {
      filterBar.isFilterVisible = false
    }
    // Update header bar height, in case filters have changed.
    let headerView = appBar.headerView
    headerView.minimumHeight = minHeaderHeight
    headerView.maximumHeight = maxHeaderHeight

    appBar.headerStackView.setNeedsLayout()
  }

  private func updateBackgroundView() {
    if scheduleViewModel.wrappedModel.shouldShowOnlySavedItems &&
      scheduleViewModel.isEmpty() {
      collectionView?.backgroundView = emptyMyIOView.configureForMyIO()
    } else if scheduleViewModel.wrappedModel.filterViewModel.filterString != nil &&
      scheduleViewModel.isEmpty() {
      collectionView?.backgroundView = emptyMyIOView.configureForEmptyFilter()
    } else {
      collectionView?.backgroundView = nil
    }
  }

// MARK: - View setup

  fileprivate enum Constants {
    static let filterButtonTitle = NSLocalizedString("Filter", comment: "Title for filter button")
    static let title = NSLocalizedString("Schedule", comment: "Title for schedule page")
    static let myIOToggleAccessibilityLabelOff =
        NSLocalizedString("Show only your events", comment: "Accessibility label for my IO toggle")
    static let myIOToggleAccessibilityLabelOn =
      NSLocalizedString("Show all events", comment: "Accessibility label for my IO toggle")
    static let headerFilterHeight: CGFloat = 56
    static let bottomButtonOffset: CGFloat = 17.0
    static let headerForegroundColor: UIColor = MDCPalette.grey.tint800
  }

  @objc override var minHeaderHeight: CGFloat {
    return super.minHeaderHeight + (filterBar.isFilterVisible ? Constants.headerFilterHeight : 0)
  }

  @objc override var maxHeaderHeight: CGFloat {
    return super.maxHeaderHeight
  }

  @objc override func setupViews() {
    super.setupViews()

    self.title = Constants.title

    self.setupCollectionView()
    self.setupNavigationBarActions()

    view.addSubview(filterButton)

    setupConstraints()

    // 3D touch
    setup3DTouch()
  }

  func setupConstraints() {
    filterButton.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor,
                                         constant: -(Constants.bottomButtonOffset)).isActive = true
    filterButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor,
                                           constant: -(Constants.bottomButtonOffset)).isActive = true
  }

  func setupNavigationBarActions() {
    navigationItem.leftBarButtonItem = setupSwitchBarButton()
    navigationItem.rightBarButtonItem = setupSearchButton()
  }

  @objc override func setupAppBar() -> MDCAppBarViewController {
    let appBar = super.setupAppBar()

    appBar.headerStackView.topBar = nil

    let stack = HeaderStack()
    stack.add(view: appBar.navigationBar)
    stack.add(view: tabBar)
    stack.add(view: filterBar)

    appBar.headerStackView.bottomBar = stack
    appBar.headerStackView.setNeedsLayout()

    // Update header bar height.
    let headerView = appBar.headerView
    headerView.minimumHeight = minHeaderHeight
    headerView.maximumHeight = maxHeaderHeight

    return appBar
  }

  func setupTabBar() -> MDCTabBar {
    let tabBar = MDCTabBar()
    tabBar.alignment = .justified
    tabBar.tintColor = tabBarTintColor
    tabBar.selectedItemTintColor = UIColor(hex: TooltipsConstants.titleColor)
    tabBar.unselectedItemTintColor = headerForegroundColor
    tabBar.itemAppearance = .titles
    tabBar.titleTextTransform = .none
    tabBar.delegate = self

    return tabBar
  }

  func setupFilterBar() -> FilterBar {
    let filterBar = FilterBar(frame: .zero, viewModel: scheduleViewModel.wrappedModel)
    return filterBar
  }

  func setupFilterFloatingButton() -> MDCFloatingButton {
    filterButton = MDCFloatingButton()
    filterButton.translatesAutoresizingMaskIntoConstraints = false
    filterButton.addTarget(self, action: #selector(filterAction), for: .touchUpInside)
    filterButton.backgroundColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    let filterImage = UIImage(named: "ic_filter_selected")?.withRenderingMode(.alwaysTemplate)
    filterButton.setImage(filterImage, for: .normal)
    filterButton.tintColor = UIColor.white
    filterButton.accessibilityLabel =
      NSLocalizedString("Filter schedule events.",
                        comment: "Accessibility label for users to filter schedule events.")
    return filterButton
  }

  func setupSwitchBarButton() -> UIBarButtonItem {
    switchBarButton.setImage(UIImage(named: "ic_myio_off"), for: .normal)
    switchBarButton.imageView?.contentMode = .scaleAspectFit
    switchBarButton.imageEdgeInsets = UIEdgeInsets(top: -4, left: -8, bottom: -4, right: -8)
    switchBarButton.contentHorizontalAlignment = .fill
    switchBarButton.contentVerticalAlignment = .fill
    switchBarButton.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
    switchBarButton.accessibilityLabel = Constants.myIOToggleAccessibilityLabelOff
    switchBarButton.sizeToFit()

    let barButtonContainerView: BarButtonContainerView = BarButtonContainerView(view: switchBarButton)
    return UIBarButtonItem(customView: barButtonContainerView)
  }

  func setupSearchButton() -> UIBarButtonItem {
    let button = MDCFlatButton()
    button.setImage(UIImage(named: "ic_search"), for: .normal)
    button.imageView?.contentMode = .scaleAspectFit
    button.contentHorizontalAlignment = .fill
    button.contentVerticalAlignment = .fill
    button.addTarget(self, action: #selector(showSearchController(_:)), for: .touchUpInside)
    button.accessibilityLabel =
      NSLocalizedString("Search",
                        comment: "Accessibility label for the search button")
    button.sizeToFit()

    let barButtonContainerView: BarButtonContainerView = BarButtonContainerView(view: button)
    return UIBarButtonItem(customView: barButtonContainerView)
  }

  public let searchViewController: SearchCollectionViewController

  func setupCollectionView() {
    collectionView?.register(ScheduleViewCollectionViewCell.self,
                             forCellWithReuseIdentifier: ScheduleViewCollectionViewCell.reuseIdentifier())
    collectionView?.register(ScheduleSectionHeaderReusableView.self,
                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                             withReuseIdentifier: ScheduleSectionHeaderReusableView.reuseIdentifier())
    collectionView?.register(AgendaSectionHeaderReusableView.self,
                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                             withReuseIdentifier: AgendaSectionHeaderReusableView.reuseIdentifier())
    collectionView?.register(AgendaCollectionViewCell.self,
                             forCellWithReuseIdentifier: AgendaCollectionViewCell.reuseIdentifier())
    styler.cellStyle = .default
    styler.shouldAnimateCellsOnAppearance = false
  }

// MARK: - Analytics

  fileprivate func logSelectedDay() {
    guard let itemID = screenName else { return }
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.screen,
      AnalyticsParameterItemID: itemID
    ])
  }

  override var screenName: String? {
    switch selectedTabIndex {
    case 0 ..< tabBar.items.count:
      return AnalyticsParameters.itemID(forSelectedDay: selectedTabIndex)

    case _:
      return nil
    }
  }

}

// MARK: - MDCTabBarDelegate
extension ScheduleViewController: MDCTabBarDelegate {

  func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
    guard let itemIndex = tabBar.items.index(of: item) else { return }
    selectedTabIndex = itemIndex
  }

  func tabBar(_ tabBar: MDCTabBar, shouldSelect item: UITabBarItem) -> Bool {
    guard let itemIndex = tabBar.items.index(of: item) else { return false }
    let section = Int(itemIndex)
    let sectionIsEmpty = scheduleViewModel.isEmpty(forDayWithIndex: section)

    return !sectionIsEmpty
  }

}

// MARK: - Actions
extension ScheduleViewController {

  @objc func filterAction() {
    scheduleViewModel.filterSelected()
  }

  @objc func switchButtonTapped() {
    if !showBookmarkedAndReserved {
      self.switchBarButton.setImage(UIImage(named: "ic_myio_on"), for: .normal)
      self.showBookmarkedAndReserved = true
      scheduleViewModel.showOnlySavedEvents()
      switchBarButton.accessibilityLabel = Constants.myIOToggleAccessibilityLabelOn
    } else {
      self.switchBarButton.setImage(UIImage(named: "ic_myio_off"), for: .normal)
      self.showBookmarkedAndReserved = false
      scheduleViewModel.showAllEvents()
      switchBarButton.accessibilityLabel = Constants.myIOToggleAccessibilityLabelOff
    }
    self.refreshUI()
  }

  @objc func showSearchController(_ sender: Any) {
    navigationController?.pushViewController(searchViewController, animated: true)
  }

  func refreshContent() {
    scheduleViewModel.updateModel()
  }
}

// MARK: - UICollectionView Layout
extension ScheduleViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    var size = scheduleViewModel.sizeForHeader(inSection: section, inFrame: collectionView.bounds)
    guard size.height > 0 else { return size }
    size.height = 8 // hack
    return size
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    let leftInset = (collectionViewLayout as? SideHeaderCollectionViewLayout)?.dateWidth ?? 0
    var frame = collectionView.bounds
    frame.size.width -= leftInset
    return scheduleViewModel.heightForCell(at: indexPath, inFrame: frame)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               shouldHideHeaderBackgroundForSection section: Int) -> Bool {
    return true
  }

}

// MARK: - UICollectionViewDelegate

extension ScheduleViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    super.collectionView(collectionView, didSelectItemAt: indexPath)
    scheduleViewModel.collectionView(collectionView, didSelectItemAt: indexPath)
  }

  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    super.scrollViewDidScroll(scrollView)
    guard let collectionView = scrollView as? UICollectionView else { return }

    // Updates the tab bar's selection without scrolling if the user scrolls to the
    // next day.
    guard scrollView.isDragging else { return }
    guard let firstVisibleItem = collectionView.indexPathsForVisibleItems.first else { return }
    let dayForItem = scheduleViewModel.dayForSection(firstVisibleItem.section)
    if tabBar.selectedItem != tabBar.items[dayForItem] {
      tabBar.setSelectedItem(tabBar.items[dayForItem], animated: true)
    }
  }

}

extension ScheduleViewController: UIViewControllerPreviewingDelegate {

  func setup3DTouch() {
    if let collectionView = collectionView {
      registerForPreviewing(with: self, sourceView: collectionView)
    }
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                         viewControllerForLocation location: CGPoint) -> UIViewController? {
    if let indexPath = collectionView?.indexPathForItem(at: location), let cellAttributes = collectionView?.layoutAttributesForItem(at: indexPath) {
      // This will show the cell clearly and blur the rest of the screen for our peek.
      previewingContext.sourceRect = cellAttributes.frame

      return scheduleViewModel.previewViewControllerForItemAt(indexPath: indexPath)
    }
    return nil
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                         commit viewControllerToCommit: UIViewController) {
    self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
  }

}

// MARK: - Dynamic type

extension ScheduleViewController {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    scheduleViewModel.invalidateHeights()
    collectionView?.collectionViewLayout.invalidateLayout()
    collectionView?.reloadData()
  }

}
