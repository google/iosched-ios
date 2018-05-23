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
import Platform

class ScheduleViewController: BaseCollectionViewController {

  private enum MyIOLayoutConstants {
    static let placeholderImageName = "ic_account_circle"
    static let userImageDimension = 72
    static let avatarImageWidth = 24
    static let avatarImageSize = CGSize(width: MyIOLayoutConstants.avatarImageWidth,
                                        height: MyIOLayoutConstants.avatarImageWidth)
  }

  fileprivate enum TooltipsConstants {
    static let titleColor = "#424242"
    static let titleFont = "Product Sans"
    static let titleFontSize: CGFloat = 20
    static let subtitleColor = "#747474"
    static let filterIcon: UIImage? = UIImage(named: "ic_myio_off")
    static let saveIcon: UIImage? = UIImage(named: "ic_session_bookmark-dark")
    static let reserveIcon: UIImage? = UIImage(named: "ic_session_reserve-dark")
    static let buttonColor = "#4768fd"
    static let buttonFont = "Product Sans"
    static let buttonFontSize: CGFloat = 14
  }

  private let agendaDataSource = AgendaDataSource()
  lazy var filterBar: FilterBar = self.setupFilterBar()
  lazy var filterButton: MDCFloatingButton = self.setupFilterFloatingButton()
  fileprivate lazy var accountButton: UIBarButtonItem = self.setupAccountButton(tint: true)
  lazy var switchBarButton: MDCFlatButton = MDCFlatButton()
  var showBookmarkedAndReserved: Bool = false
  lazy var tabBar: MDCTabBar = self.setupTabBar()
  lazy var agendaTabBarItem = self.setupAgendaTabBarItem()
  lazy var emptyMyIOView = ScheduleCollectionEmptyView()
  var selectedTabIndex = 0 {
    didSet {
      collectionView?.reloadData()
      updateBackgroundView()
      logSelectedDay()
    }
  }

  func selectDay(day: Int) {
    if day < tabBar.items.count {
      selectedTabIndex = day
      tabBar.selectedItem = tabBar.items[day]
      currentViewModel.selectedDay = selectedTabIndex
    }
  }

  var currentViewModel: ScheduleComposedViewModel
  let scheduleViewModel: ScheduleComposedViewModel
  let myIOViewModel: MyIOComposedViewModel

  init(viewModel: ScheduleComposedViewModel, myIOViewModel: MyIOComposedViewModel) {
    self.scheduleViewModel = viewModel
    self.currentViewModel = viewModel
    self.myIOViewModel = myIOViewModel
    let layout = ScheduleCollectionViewLayout()
    layout.headerReferenceSize = CGSize(width: 60, height: 8)
    layout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.size.width, height: 120)
    super.init(collectionViewLayout: ScheduleCollectionViewLayout())
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
    showInitialTooltipsIfNeeded()
    registerForAccountUpdates()
    registerForViewUpdates()
    registerForDynamicTypeUpdates()
    refreshContent()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    logSelectedDay()
  }
  
  func showInitialTooltipsIfNeeded() {
    if (!DefaultServiceLocator.sharedInstance.userState.shouldShowInitialTooltips) {
      return;
    }

    let alertController: MDCAlertController =
        MDCAlertController(title: NSLocalizedString("Customize your schedule",
                                                    comment: "Tooltips title"),
                           message:"")
    alertController.addAction(MDCAlertAction(title: "Got it", handler: { (action: MDCAlertAction) in
      alertController.dismiss(animated: true, completion: nil)
    }))
    alertController.titleFont = UIFont(name: TooltipsConstants.titleFont, size: TooltipsConstants.titleFontSize)
    alertController.titleColor = UIColor(hex: TooltipsConstants.titleColor)
    alertController.messageColor = UIColor(hex: TooltipsConstants.subtitleColor)
    alertController.buttonFont = UIFont(name: TooltipsConstants.buttonFont, size: TooltipsConstants.buttonFontSize)
    alertController.buttonTitleColor = UIColor(hex: TooltipsConstants.buttonColor)

    // Using private API of MDCAlertControllerView for customization.
    if (alertController.view.responds(to: NSSelectorFromString("messageLabel"))) {
      let messageLabel: UILabel = alertController.view.perform(NSSelectorFromString("messageLabel")).takeUnretainedValue() as! UILabel

      let tooltipsMutableString = NSMutableAttributedString()
      let attributes = [
        NSAttributedStringKey.foregroundColor: UIColor(hex: TooltipsConstants.subtitleColor),
        ] as [NSAttributedStringKey : Any]

      let filterAttachment = NSTextAttachment()
      filterAttachment.image = TooltipsConstants.filterIcon
      filterAttachment.bounds = CGRect(x: 0, y: -5, width: (filterAttachment.image?.size.width)!, height: (filterAttachment.image?.size.height)!)

      let filterAttachmentString = NSAttributedString(attachment: filterAttachment)
      let filterString = NSAttributedString(string: String(format: "   %@\n\n", NSLocalizedString("View only your events", comment: "Tooltips explanation of filtering")), attributes:attributes)

      tooltipsMutableString.append(filterAttachmentString)
      tooltipsMutableString.append(filterString)
      
      let saveAttachment = NSTextAttachment()
      saveAttachment.image = TooltipsConstants.saveIcon
      saveAttachment.bounds = CGRect(x: 0, y: -4, width: (saveAttachment.image?.size.width)!, height: (saveAttachment.image?.size.height)!)
      let saveAttachmentString = NSAttributedString(attachment: saveAttachment)
      let saveString = NSAttributedString(string: String(format: "   %@\n\n", NSLocalizedString("Save an event", comment: "Tooltips explanation of saving an event")), attributes:attributes)
      
      tooltipsMutableString.append(NSAttributedString(string: " "))
      tooltipsMutableString.append(saveAttachmentString)
      tooltipsMutableString.append(saveString)
      
      let reserveAttachment = NSTextAttachment()
      reserveAttachment.image = TooltipsConstants.reserveIcon
      reserveAttachment.bounds = CGRect(x: 0, y: -7, width: (reserveAttachment.image?.size.width)!, height: (reserveAttachment.image?.size.height)!)
      let reserveAttachmentString = NSAttributedString(attachment: reserveAttachment)
      let reserveString = NSAttributedString(string: String(format: "   %@", NSLocalizedString("Reserve a session seat", comment: "Tooltips explanation of reserving an event")), attributes:attributes)
      
      tooltipsMutableString.append(NSAttributedString(string: " "))
      tooltipsMutableString.append(reserveAttachmentString)
      tooltipsMutableString.append(reserveString)

      messageLabel.attributedText = tooltipsMutableString
    }
    self.present(alertController, animated: true) {
      DefaultServiceLocator.sharedInstance.userState.setInitialTooltipsShown(true)
    }
  }

  func registerForAccountUpdates() {
    // update avatar first ...
    self.updateAvatarImage()

    // ... then register for subsequent updates
    SignIn.sharedInstance
      .onSignIn {
        self.updateAvatarImage()
        self.refreshContent()
      }
      .onSignOut {
        self.updateAvatarImage()
        self.refreshContent()
    }
  }

  func registerForViewUpdates() {
    currentViewModel.onUpdate { indexPath in
      self.performViewUpdate(indexPath: indexPath)
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

    let items = currentViewModel.conferenceDays.map {
      UITabBarItem(title: $0.dayString, image: nil, tag: 0)
    }
    + [agendaTabBarItem]
    tabBar.items = items
  }

  func refreshUI() {
    var selectedIndex = 0
    if let selectedItem = tabBar.selectedItem {
      selectedIndex = tabBar.items.index(of: selectedItem) ?? 0
    }

    if currentViewModel.conferenceDays.count > 0 {
      updateTabBarItems()
      tabBar.selectedItem = tabBar.items[selectedIndex]
    }

    updateBackgroundView()
    self.collectionView?.reloadData()

    if let filterString = currentViewModel.wrappedModel.filterViewModel.filterString {
      filterBar.isFilterVisible = true
      filterBar.filterText = filterString
    } else {
      filterBar.isFilterVisible = false
    }
    // Update header bar height.
    let headerView = appBar.headerViewController.headerView
    headerView.minimumHeight = minHeaderHeight
    headerView.maximumHeight = maxHeaderHeight

    appBar.headerStackView.setNeedsLayout()
  }

  func updateAvatarImage() {
    if let user = GIDSignIn.sharedInstance().currentUser {
      if let url = user.profile.imageURL(withDimension: UInt(MyIOLayoutConstants.userImageDimension)) {
        self.downloadAvatarImage(url)
      }
    }
    else {
      if let placeholderImage = self.placeholderImage {
        self.accountImage = placeholderImage
      }
      self.updateAccountButton(tint: true)
    }
  }

  private func updateBackgroundView() {
    if tabBar.selectedItem == agendaTabBarItem {
      collectionView?.backgroundView = nil
    } else if currentViewModel === myIOViewModel &&
      myIOViewModel.isEmpty(forDayWithIndex: selectedTabIndex) {
      collectionView?.backgroundView = emptyMyIOView.configureForMyIO()
    } else if (currentViewModel.wrappedModel.filterViewModel.filterString != nil) &&
      currentViewModel.isEmpty() {
      collectionView?.backgroundView = emptyMyIOView.configureForEmptyFilter()
    } else {
      collectionView?.backgroundView = nil
    }
  }

  let placeholderImage = UIImage(named: MyIOLayoutConstants.placeholderImageName)?
      .withRenderingMode(.alwaysTemplate)
  lazy var accountImage: UIImage? = self.placeholderImage

  lazy var imageDownloader: ImageDownloader = ImageDownloader()
  lazy var avatarFilter = AspectScaledToFillSizeCircleFilter(size: MyIOLayoutConstants.avatarImageSize)

  func downloadAvatarImage(_ url: URL) {
    let urlRequest = URLRequest(url: url)

    imageDownloader.download(urlRequest, filter: avatarFilter) { response in
      if let image = response.result.value {
        self.accountImage = image
        self.updateAccountButton(tint: false)
      }
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

  private class HeaderStack: UIView {
    private var views = [UIView]()

    override init(frame: CGRect) {
      super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
      let totalHeight = views.map { $0.sizeThatFits(size).height }.reduce(0, +)
      return CGSize(width: size.width, height: totalHeight)
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      // Layout bottom to top using each item's size.
      var remainingSize = bounds.size
      for view in views.reversed() {
        let viewHeight = view.sizeThatFits(remainingSize).height
        let y = max(0, remainingSize.height - viewHeight)
        let height = min(viewHeight, remainingSize.height)
        view.frame = CGRect(x: 0, y: y, width: remainingSize.width, height: height)
        remainingSize = CGSize(width: remainingSize.width, height: remainingSize.height - height)
      }
    }

    func add(view: UIView) {
      views.append(view)
      addSubview(view)
    }
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
    let tabBarOffset = self.tabBarController?.tabBar.frame.height ?? 0
    filterButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                         constant: -(tabBarOffset + Constants.bottomButtonOffset)).isActive = true
    // TODO(benwlee): filterButton will also need to account for bottom notification bar appearing.
    filterButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor,
                                           constant: -(Constants.bottomButtonOffset)).isActive = true
  }

  func setupNavigationBarActions() {
    self.navigationItem.leftBarButtonItem = accountButton
    self.navigationItem.rightBarButtonItem = setupSwitchBarButton()
  }

  @objc override func setupAppBar() -> MDCAppBar {
    let appBar = super.setupAppBar()

    appBar.headerStackView.topBar = nil

    let stack = HeaderStack()
    stack.add(view: appBar.navigationBar)
    stack.add(view: self.tabBar)
    stack.add(view: self.filterBar)

    appBar.headerStackView.bottomBar = stack
    appBar.headerStackView.setNeedsLayout()

    // Update header bar height.
    let headerView = appBar.headerViewController.headerView
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

  func setupAgendaTabBarItem() -> UITabBarItem {
    let title = NSLocalizedString("Agenda",
                                  comment: "Title of a tab button displaying schedule information")
    return UITabBarItem(title: title, image: nil, tag: 0)
  }

  func setupFilterBar() -> FilterBar {
    let filterBar = FilterBar()
    filterBar.scheduleViewModel = currentViewModel.wrappedModel
    return filterBar
  }

  func updateAccountButton(tint: Bool) {
    self.accountButton = setupAccountButton(tint: tint)
    setupNavigationBarActions()
  }

  func setupAccountButton(tint: Bool) -> UIBarButtonItem {
    let image = self.accountImage
    let button = UIBarButtonItem.init(image: image,
                                      style: .plain,
                                      target: self,
                                      action: #selector(accountAction))    
    if tint {
      button.tintColor = headerForegroundColor
    }
    button.accessibilityLabel = NSLocalizedString("User account information",
                                                  comment: "Accessibility label for user account button")
    return button
  }

  func setupFilterFloatingButton() -> MDCFloatingButton {
    filterButton = MDCFloatingButton()
    filterButton.translatesAutoresizingMaskIntoConstraints = false
    filterButton.addTarget(self, action: #selector(filterAction), for: .touchUpInside)
    filterButton.backgroundColor = UIColor(hex: "#4768fd")
    let filterImage = UIImage(named: "ic_filter_selected")?.withRenderingMode(.alwaysTemplate)
    filterButton.setImage(filterImage, for: .normal)
    filterButton.tintColor = UIColor.white
    filterButton.accessibilityLabel =
      NSLocalizedString("Filter schedule events.",
                        comment: "Accessibility label for users to filter schedule events.")
    return filterButton
  }

  func setupSwitchBarButton() -> UIBarButtonItem {
    switchBarButton.setImage(UIImage(named:"ic_myio_off"), for: .normal)
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

  func setupCollectionView() {
    collectionView?.register(ScheduleViewCollectionViewCell.self,
                             forCellWithReuseIdentifier: ScheduleViewCollectionViewCell.reuseIdentifier())
    collectionView?.register(IOSchedCollectionViewHeaderCell.self,
                             forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                             withReuseIdentifier: IOSchedCollectionViewHeaderCell.reuseIdentifier())
    collectionView?.register(AgendaCollectionViewHeaderCell.self,
                             forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                             withReuseIdentifier: AgendaCollectionViewHeaderCell.reuseIdentifier())
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
    selectedTabIndex = tabBar.items.index(of: item) ?? 0
    if selectedTabIndex < currentViewModel.conferenceDays.count {
      currentViewModel.selectedDay = selectedTabIndex
    } else {
      updateBackgroundView()
      collectionView?.reloadData()
    }
  }
}

// MARK: - Actions
extension ScheduleViewController {
  @objc func accountAction() {
    currentViewModel.accountSelected()
  }

  @objc func filterAction() {
    currentViewModel.filterSelected()
  }

  @objc func switchButtonTapped() {
    if !showBookmarkedAndReserved {
      self.switchBarButton.setImage(UIImage(named:"ic_myio_on"), for: .normal)
      self.showBookmarkedAndReserved = true
      self.currentViewModel = self.myIOViewModel
      switchBarButton.accessibilityLabel = Constants.myIOToggleAccessibilityLabelOn
    } else {
      self.switchBarButton.setImage(UIImage(named:"ic_myio_off"), for: .normal)
      self.showBookmarkedAndReserved = false
      self.currentViewModel = self.scheduleViewModel
      switchBarButton.accessibilityLabel = Constants.myIOToggleAccessibilityLabelOff
    }
    if tabBar.selectedItem != agendaTabBarItem {
      currentViewModel.selectedDay = selectedTabIndex
      self.refreshUI()
    }
  }

  func refreshContent() {
    DefaultServiceLocator.sharedInstance.updateConferenceData { [weak self] in
      self?.currentViewModel.updateModel()
    }
  }
}

// MARK: - UICollectionView Layout
extension ScheduleViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    guard tabBar.selectedItem != agendaTabBarItem else {
      return CGSize(width: view.frame.size.width, height: 48)
    }
    var size = currentViewModel.sizeForHeader(inSection: section, inFrame: collectionView.bounds)
    size.height = 8 // totally not a hack
    return size
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    if tabBar.selectedItem == agendaTabBarItem {
      return AgendaCollectionViewCell.cellHeight
    }
    let leftInset = (collectionViewLayout as? ScheduleCollectionViewLayout)?.dateWidth ?? 0
    var frame = collectionView.bounds
    frame.size.width -= leftInset
    return currentViewModel.heightForCell(at: indexPath, inFrame: frame)
  }

  override func collectionView(_ collectionView: UICollectionView, shouldHideHeaderBackgroundForSection section: Int) -> Bool {
    return true
  }

  override func collectionView(_ collectionView: UICollectionView, cellBackgroundColorAt indexPath: IndexPath) -> UIColor? {
    return currentViewModel.backgroundColor(at: indexPath) ?? .white
  }

}

// MARK: - UICollectionViewDataSource
extension ScheduleViewController {

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    if tabBar.selectedItem == agendaTabBarItem {
      return agendaDataSource.numberOfSections(in: collectionView)
    }
    return currentViewModel.numberOfSections()
  }

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    if tabBar.selectedItem == agendaTabBarItem {
      return agendaDataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }
    let numberOfItemsIn = currentViewModel.numberOfItemsIn(section: section)
    return numberOfItemsIn
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if tabBar.selectedItem == agendaTabBarItem {
      return agendaDataSource.collectionView(collectionView, cellForItemAt: indexPath)
    }
    if let cellClass = currentViewModel.cellClassForItemAt(indexPath: indexPath) {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellClass.reuseIdentifier(), for: indexPath)
      currentViewModel.populateCell(cell, forItemAt: indexPath)
      return cell
    }
    fatalError("This should not happen.")
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    if tabBar.selectedItem == agendaTabBarItem {
      return agendaDataSource.collectionView(collectionView,
                                             viewForSupplementaryElementOfKind: kind,
                                             at: indexPath)
    }
    guard let viewClass = currentViewModel.supplementaryViewClass(ofKind: kind, forItemAt: indexPath) else {
      fatalError("ViewModel must provide class name for supplementary view.")
    }
    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                               withReuseIdentifier: viewClass.reuseIdentifier(),
                                                               for: indexPath)
    if kind == UICollectionElementKindSectionHeader {
      if currentViewModel.numberOfItemsIn(section: indexPath.section) == 0,
          let headerView = view as? IOSchedCollectionViewHeaderCell {
        headerView.date = nil
        headerView.isHidden = true
      } else {
        view.isHidden = false
      }
    }
    currentViewModel.populateSupplementaryView(view, forItemAt: indexPath)
    return view
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    currentViewModel.didSelectItemAt(indexPath: indexPath)
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
    guard tabBar.selectedItem != agendaTabBarItem else { return nil }
    if let indexPath = collectionView?.indexPathForItem(at: location), let cellAttributes = collectionView?.layoutAttributesForItem(at: indexPath) {
      // This will show the cell clearly and blur the rest of the screen for our peek.
      previewingContext.sourceRect = cellAttributes.frame

      return currentViewModel.previewViewControllerForItemAt(indexPath: indexPath)
    }
    return nil
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
  }

}

// MARK: - Dynamic type

extension ScheduleViewController {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: .UIContentSizeCategoryDidChange,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    scheduleViewModel.invalidateHeights()
    myIOViewModel.invalidateHeights()
    collectionView?.collectionViewLayout.invalidateLayout()
    collectionView?.reloadData()
  }

}
