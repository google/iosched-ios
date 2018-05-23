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

class HomeViewController: BaseCollectionViewController {

  private let serviceLocator: ServiceLocator
  private let rootNavigator: RootNavigator

  private var sessionsDataSource: LazyReadonlySessionsDataSource {
    return serviceLocator.sessionsDataSource
  }

  private lazy var scheduleNavigator: ScheduleNavigator =
      DefaultScheduleNavigator(serviceLocator: serviceLocator,
                               rootNavigator: rootNavigator,
                               navigationController: navigationController!)

  public private(set) lazy var searchViewController: SearchCollectionViewController = {
    let controller =
        SearchCollectionViewController(rootNavigator: rootNavigator, serviceLocator: serviceLocator)
    controller.scheduleNavigator = scheduleNavigator
    return controller
  }()

  private lazy var dataSource: HomeCollectionViewDataSource =
      HomeCollectionViewDataSource(sessions: sessionsDataSource,
                                   navigator: scheduleNavigator,
                                   rootNavigator: rootNavigator)

  private lazy var logoView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "logo")
    imageView.contentMode = .center
    imageView.isAccessibilityElement = true
    imageView.accessibilityLabel = NSLocalizedString("Home", comment: "Title of the Home screen.")
    return imageView
  }()

  public init(serviceLocator: ServiceLocator,
              navigator: RootNavigator) {
    self.serviceLocator = serviceLocator
    rootNavigator = navigator
    let layout = MDCCollectionViewFlowLayout()
    layout.minimumLineSpacing = 8
    super.init(collectionViewLayout: layout)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    registerForDynamicTypeUpdates()
    registerForTimeZoneChanges()

    collectionView.backgroundColor = .white
    collectionView.register(
      UpcomingItemsCollectionViewCell.self,
      forCellWithReuseIdentifier: UpcomingItemsCollectionViewCell.reuseIdentifier()
    )
    collectionView.register(
      HomeCollectionViewHeadlinerCell.self,
      forCellWithReuseIdentifier: HomeCollectionViewHeadlinerCell.reuseIdentifier()
    )
    collectionView.register(
      HomeFeedItemCollectionViewCell.self,
      forCellWithReuseIdentifier: HomeFeedItemCollectionViewCell.reuseIdentifier()
    )
    collectionView.register(
      NoAnnouncementsCollectionViewCell.self,
      forCellWithReuseIdentifier: NoAnnouncementsCollectionViewCell.reuseIdentifier()
    )
    collectionView.register(HomeCollectionViewSectionHeader.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: HomeCollectionViewSectionHeader.reuseIdentifier())
    navigationItem.rightBarButtonItem = searchButton
    navigationItem.titleView = logoView
    collectionView.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    dataSource.syncFeedItems { _ in
      self.collectionView.reloadSections([2])
      self.dataSource.stopSyncing()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    dataSource.shouldRegenerateHeaderAnimation = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // The countdown view gets stuck sometimes after a navigation push/pop.
    collectionView.reloadData()
  }

  // MARK: - Search button

  private let searchButton: UIBarButtonItem = {
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
  }()

  @objc private func showSearchController(_ sender: Any) {
    navigationController?.pushViewController(searchViewController, animated: true)
  }

  override var minHeaderHeight: CGFloat {
    return 56 + UIApplication.shared.statusBarFrame.height
  }

  override var maxHeaderHeight: CGFloat {
    return 56 + UIApplication.shared.statusBarFrame.height
  }

  // MARK: - UICollectionViewDataSource

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return dataSource.numberOfSections(in: collectionView)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return dataSource.collectionView(collectionView, numberOfItemsInSection: section)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return dataSource.collectionView(collectionView, cellForItemAt: indexPath)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {

    switch indexPath.section {
    case 0:
      return HomeCollectionViewHeadlinerCell.cellHeight
    case 1:
      return UpcomingItemsCollectionViewCell.cellHeight
    case 2:
      return dataSource.sizeForItem(index: indexPath.item,
                                    maxWidth: collectionView.frame.size.width - 64).height
    case _:
      return 0
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
    switch section {
    case 2:
      return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

    case _:
      return super.collectionView(collectionView,
                                  layout: collectionViewLayout,
                                  insetForSectionAt: section)
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    return dataSource.collectionView(collectionView,
                                     viewForSupplementaryElementOfKind: kind,
                                     at: indexPath)
  }

  // MARK: - UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView,
                               shouldSelectItemAt indexPath: IndexPath) -> Bool {
    guard indexPath.section == 0 && indexPath.item == 0 else { return false }
    guard let currentMoment = Moment.currentMoment() else { return false }
    return dataSource.canSelectMoment(currentMoment)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    guard indexPath.section == 0 && indexPath.item == 0 else { return }
    guard let moment = Moment.currentMoment(), dataSource.canSelectMoment(moment) else { return }
    collectionView.deselectItem(at: indexPath, animated: true)

    dataSource.selectMoment(moment)
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    return dataSource.collectionView(collectionView,
                                     layout: collectionViewLayout,
                                     referenceSizeForHeaderInSection: section)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

// MARK: - Dynamic type

extension HomeViewController {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    collectionView?.reloadData()
    collectionView?.collectionViewLayout.invalidateLayout()
  }

  func registerForTimeZoneChanges() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(timeZoneDidChange(_:)),
                                           name: .timezoneUpdate,
                                           object: nil)
  }

  @objc private func timeZoneDidChange(_ notification: Any) {
    collectionView.reloadData()
  }

}
