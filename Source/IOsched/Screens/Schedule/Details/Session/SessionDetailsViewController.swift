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
import YouTubePlayer

fileprivate enum Constants {
  static let shareIcon = "ic_share"
  static let mapIcon = "ic_map_white"
  static let toggleBookmarkText = "Toggle Bookmark"
}

class SessionDetailsViewController: BaseCollectionViewController {

  var viewModel: SessionDetailsViewModel?

  lazy var measureMainInfoCell: SessionDetailsCollectionViewMainInfoCell = self.setupMeasureMainInfoCell()
  lazy var measureSpeakerCell: SessionDetailsCollectionViewSpeakerCell = self.setupMeasureSpeakerCell()

  lazy var bottomBarView: MDCBottomAppBarView = self.setupBottomBarView()
  lazy var youtubePlayerView: YouTubePlayerView = self.setupYoutubePlayerView()

  var youtubeURL: URL? {
    willSet {
      guard newValue != youtubeURL else { return }
      guard let url = newValue else { return }
      youtubePlayerView.loadVideoURL(url)
    }
  }

  fileprivate var bottomBarConstraint: NSLayoutConstraint?

  convenience init(viewModel: SessionDetailsViewModel) {
    self.init()
    self.viewModel = viewModel
    self.viewModel?.onUpdate { [weak self] in
      self?.updateFromViewModel()
      self?.collectionView?.reloadData()
    }
    updateFromViewModel()
  }

// Tentatively removed until we are sure we don't have any retain cycles.
//  deinit {
//    viewModel = nil
//  }

// MARK: - View setup

  private struct LayoutConstants {
    static let fabOffset: CGFloat = 17
    static let sectionHeight: CGFloat = 50
    static let headerSize = CGSize.zero
    static let headerFontName = "Product Sans"
    static let headerFont = UIFont(name: LayoutConstants.headerFontName, size: 14)
    static let headerColor = UIColor(hex: "#747474")
  }

  @objc override func setupViews() {
    super.setupViews()

    setupCollectionView()
    let shareButton = setupShareButton()
    bottomBarView.leadingBarButtonItems = [shareButton]
    view.addSubview(bottomBarView)

    setupConstraints()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    setupConstraints()
  }

  func setupConstraints() {
    let tabBarOffset = self.tabBarController?.tabBar.frame.height ?? 0

    let views = [
      "bottomBarView": bottomBarView
    ] as [String: Any]

    if bottomBarConstraint == nil {
      var constraints =
        NSLayoutConstraint.constraints(withVisualFormat: "H:|[bottomBarView]|",
                                       options: [],
                                       metrics: nil,
                                       views: views)
      bottomBarConstraint = bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBarOffset)

      if let constraint = bottomBarConstraint {
        constraints += [constraint]
      }
      constraints += [
        bottomBarView.heightAnchor.constraint(equalToConstant: 96)
      ]

      NSLayoutConstraint.activate(constraints)
    }
    else {
      bottomBarConstraint?.constant = -tabBarOffset
    }

    setup3DTouch()
  }

  override func setupAppBar() -> MDCAppBar {
    let appBar = super.setupAppBar()

    appBar.headerStackView.bottomBar = youtubePlayerView

    let views = [
      "youtubePlayerView": youtubePlayerView
    ]

    let metrics = [
      "minHeight": 200
    ]

    var constraints =
      NSLayoutConstraint.constraints(withVisualFormat: "H:|[youtubePlayerView]|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)
    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:[youtubePlayerView(>=minHeight)]|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    if let model = viewModel?.scheduleEventDetailsViewModel {
      if model.shouldDisplayVideoplayer {
        NSLayoutConstraint.activate(constraints)
      }
    }

    return appBar
  }

  func setupYoutubePlayerView() -> YouTubePlayerView {
    let youtubePlayerView = YouTubePlayerView()
    youtubePlayerView.translatesAutoresizingMaskIntoConstraints = false

    youtubePlayerView.playerVars = [
      "playsinline": NSNumber(value: 1),
      "controls": NSNumber(value: 1),
      "showinfo": NSNumber(value: 0),
      "modestbranding": NSNumber(value: 1)
    ]

    return youtubePlayerView
  }

  func setupCollectionView() {
    collectionView?.register(MDCCollectionViewTextCell.self)
    collectionView?.register(SessionDetailsCollectionViewMainInfoCell.self)
    collectionView?.register(SessionDetailsCollectionViewSpeakerCell.self)
    collectionView?.register(MDCCollectionViewTextCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader)

    styler.cellStyle = .default
    styler.shouldAnimateCellsOnAppearance = false
  }

  func setupMeasureMainInfoCell() -> SessionDetailsCollectionViewMainInfoCell {
    return SessionDetailsCollectionViewMainInfoCell(frame: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: self.view.frame.width,
                                                                  height: self.view.frame.height))
  }

  func setupMeasureSpeakerCell() -> SessionDetailsCollectionViewSpeakerCell {
    return SessionDetailsCollectionViewSpeakerCell(frame: CGRect(x: 0,
                                                                 y: 0,
                                                                 width: self.view.frame.width,
                                                                 height: self.view.frame.height))
  }

  func setupShareButton() -> UIBarButtonItem {
    let image = UIImage(named: Constants.shareIcon)?.withRenderingMode(.alwaysTemplate)
    let shareButton = UIBarButtonItem(image: image,
                                      style: .plain,
                                      target: self,
                                      action: #selector(shareAction(_:)))
    shareButton.tintColor = LayoutConstants.headerColor
    shareButton.accessibilityLabel = NSLocalizedString("Share this session", comment: "Accessibility label for sharing button.")
    return shareButton
  }

  func setupBottomBarView() -> MDCBottomAppBarView {
    bottomBarView = MDCBottomAppBarView()
    bottomBarView.translatesAutoresizingMaskIntoConstraints = false
    bottomBarView.floatingButtonPosition = .trailing
    bottomBarView.floatingButton.addTarget(self, action: #selector(toggleFavourite), for: .touchUpInside)
    return bottomBarView
  }

  fileprivate func updateFromViewModel() {
    if let model = viewModel?.scheduleEventDetailsViewModel {
      let button = bottomBarView.floatingButton
      button.backgroundColor = model.bookmarkButtonBackgroundColor
      button.setImage(model.bookmarkButtonImage, for: .normal)
      button.accessibilityLabel = model.bookmarkButtonAccessibilityLabel
      button.isHidden = !model.isBookmarkable

      youtubeURL = model.youtubeUrl
    }
  }

// MARK: - Analytics

  @objc override var screenName: String? {
    guard let title = viewModel?.scheduleEventDetailsViewModel?.title else { return nil }
    return AnalyticsParameters.itemID(forSessionTitle: title)
  }

// MARK: - ViewControllerStylable

  enum StylingConstants {

    static let maxHeaderHeight: CGFloat = 60
    static let minHeaderHeight: CGFloat = 60

    static let maxHeaderHeightWithVideoplayer: CGFloat = 200 + 60
    static let minHeaderHeightWithVideoplayer: CGFloat = 200
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }

  @objc override var minHeaderHeight: CGFloat {
    if let model = viewModel?.scheduleEventDetailsViewModel, model.shouldDisplayVideoplayer {
      return StylingConstants.minHeaderHeightWithVideoplayer + UIApplication.shared.statusBarFrame.height
    }
    return StylingConstants.minHeaderHeight + UIApplication.shared.statusBarFrame.height
  }

  @objc override var maxHeaderHeight: CGFloat {
    if let model = viewModel?.scheduleEventDetailsViewModel, model.shouldDisplayVideoplayer {
      return StylingConstants.maxHeaderHeightWithVideoplayer + UIApplication.shared.statusBarFrame.height
    }
    return StylingConstants.maxHeaderHeight + UIApplication.shared.statusBarFrame.height
  }

  @objc override var additionalBottomContentInset: CGFloat {
    return 58
  }
}

// MARK: - Actions
extension SessionDetailsViewController {
  @objc func shareAction(_ sender: Any) {
    // There's something going on that prevents our bar button item from having a nonnil
    // `view` property (private API), which cause UIPopoverPresentationController to crash
    // on iPads. This is the much more disgusting workaround.
    let rect = CGRect(x: 24, y: 54, width: 24, height: 24)
    let sourceView = bottomBarView
    viewModel?.shareSession(sourceView: sourceView, sourceRect: rect)
  }

  @objc func mapAction() {
    viewModel?.openMap()
  }

  @objc func toggleFavourite() {
    viewModel?.toggleBookmark()
    guard let title = viewModel?.scheduleEventDetailsViewModel?.title else { return }
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.uiEvent,
      AnalyticsParameterItemID: title,
      AnalyticsParameters.uiAction: AnalyticsParameters.bookmarked
    ])
  }
}

// MARK: - UICollectionView Layout

extension SessionDetailsViewController {

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    let measureCell: MDCCollectionViewCell = {
      if indexPath.section == 0 {
        return measureMainInfoCell
      }
      else {
        return measureSpeakerCell
      }
    }()

    populateCell(cell: measureCell, forItemAt: indexPath)
    return measureCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
  }

}

// MARK: - UICollectionView DataSource

extension SessionDetailsViewController {

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    switch section {
    case 0:
      return 1
    case 1:
      return viewModel?.scheduleEventDetailsViewModel?.speakers.count ?? 0
    case _:
      return 0
    }
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch indexPath.section {
    case 0:
      let cell: SessionDetailsCollectionViewMainInfoCell = collectionView.dequeueReusableCell(for: indexPath)
      populateCell(cell: cell, forItemAt: indexPath)
      return cell
    case 1:
      let cell: SessionDetailsCollectionViewSpeakerCell = collectionView.dequeueReusableCell(for: indexPath)
      populateCell(cell: cell, forItemAt: indexPath)
      return cell
    case _:
      break
    }

    fatalError("Not implemented")
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                               withReuseIdentifier: MDCCollectionViewTextCell.self.reuseIdentifier(),
                                                               for: indexPath)
    if let cell = view as? MDCCollectionViewTextCell {
      switch indexPath.section {
      case 1:
        cell.textLabel?.text = NSLocalizedString("Speakers", comment: "Header for speakers in this session").localizedUppercase
        cell.textLabel?.font = LayoutConstants.headerFont
        cell.textLabel?.textColor = LayoutConstants.headerColor
        break
      case _:
        break
      }
    }
    return view
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    if (section == 0) {
      return LayoutConstants.headerSize
    } else {
      if (collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: section) == 0) {
        return LayoutConstants.headerSize
      }
      return CGSize(width: collectionView.bounds.width, height: LayoutConstants.sectionHeight)
    }
  }

  func populateCell(cell: MDCCollectionViewCell, forItemAt indexPath: IndexPath) {
    if let cell = cell as? SessionDetailsCollectionViewMainInfoCell {
      cell.viewModel = self.viewModel
    }

    if let cell = cell as? SessionDetailsCollectionViewSpeakerCell {
      cell.viewModel = self.viewModel?.scheduleEventDetailsViewModel?.speakers[indexPath.row]
    }
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath)

    if let cell = cell as? SessionDetailsCollectionViewSpeakerCell {
      cell.viewModel?.selectSpeaker(speaker: (cell.viewModel?.speaker)!)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    return (((collectionView.cellForItem(at: indexPath) as? SessionDetailsCollectionViewSpeakerCell) != nil))
  }

}

extension SessionDetailsViewController: UIViewControllerPreviewingDelegate {

  func setup3DTouch() {
    if let collectionView = collectionView {
      registerForPreviewing(with: self, sourceView: collectionView)
    }
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                         viewControllerForLocation location: CGPoint) -> UIViewController? {
    if let indexPath = collectionView?.indexPathForItem(at: location), let cellAttributes = collectionView?.layoutAttributesForItem(at: indexPath) {
      //This will show the cell clearly and blur the rest of the screen for our peek.
      previewingContext.sourceRect = cellAttributes.frame

      return viewModel?.detailsViewController(indexPath)
    }
    return nil
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
  }

}

// MARK: - 3D Touch action items

extension SessionDetailsViewController {
  override var previewActionItems: [UIPreviewActionItem] {
    guard let viewModel = viewModel, let eventDetailsViewModel = viewModel.scheduleEventDetailsViewModel else { return [] }
    guard eventDetailsViewModel.isBookmarkable else { return [] }

    let title = eventDetailsViewModel.bookmarkPreviewActionTitle
    let actionToogleBookmark = UIPreviewAction(title: title, style: .default) { (_, _) in
      viewModel.toggleBookmark()
    }

    return [actionToogleBookmark]
  }
}

// MARK: - Scrolling

extension SessionDetailsViewController {

  private enum ScrollingConstants {
    static let cutOffHeight: CGFloat = 55
  }

  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    super.scrollViewDidScroll(scrollView)
    guard let model = viewModel?.scheduleEventDetailsViewModel else { return }
    guard model.shouldDisplayVideoplayer else { return }

    guard scrollView == appBar.headerViewController.headerView.trackingScrollView else { return }

    let minimumHeight = appBar.headerViewController.headerView.minimumHeight
    let offset = scrollView.contentOffset.y

    let remainingheight = max(0, -offset - minimumHeight)
    let height = min(ScrollingConstants.cutOffHeight, remainingheight)
    let alpha = height / ScrollingConstants.cutOffHeight
    appBar.headerStackView.topBar?.alpha = alpha
  }

}
