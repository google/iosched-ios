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

private enum Constants {
  static let shareIcon = "ic_share"
  static let mapIcon = "ic_map_white"
  static let toggleBookmarkText = "Toggle Bookmark"
}

class SessionDetailsViewController: BaseCollectionViewController {

  var viewModel: SessionDetailsViewModel

  lazy var measureMainInfoCell: SessionDetailsCollectionViewMainInfoCell =
      self.setupMeasureMainInfoCell()
  lazy var measureSpeakerCell: SessionDetailsCollectionViewSpeakerCell =
      self.setupMeasureSpeakerCell()

  lazy var bottomBarView: MDCBottomAppBarView = self.setupBottomBarView()
  lazy var youtubePlayerView: YouTubePlayerView = self.setupYoutubePlayerView()
  lazy var headerImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()

  var youtubeURL: URL? {
    willSet {
      guard newValue != youtubeURL else { return }
      guard let url = newValue else { return }
      youtubePlayerView.loadVideoURL(url)
    }
  }

  fileprivate var bottomBarConstraint: NSLayoutConstraint?

  required init(viewModel: SessionDetailsViewModel) {
    self.viewModel = viewModel
    super.init(collectionViewLayout: MDCCollectionViewFlowLayout())
    self.viewModel.onUpdate { [weak self] in
      guard let strongSelf = self else { return }
      strongSelf.updateFromViewModel()
      strongSelf.collectionView.reloadData()
    }
    updateFromViewModel()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

// MARK: - View setup

  private struct LayoutConstants {
    static let fabOffset: CGFloat = 17
    static let sectionHeight: CGFloat = 50
    static let headerSize = CGSize.zero
    static func headerFont() -> UIFont {
      return ProductSans.regular.style(.footnote, sizeOffset: 1)
    }
    static let headerColor = UIColor(red: 95 / 255, green: 99 / 255, blue: 104 / 255, alpha: 1)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    registerForTimeZoneChanges()
  }

  @objc override func setupViews() {
    super.setupViews()

    setupCollectionView()
    let shareButton = setupShareButton()
    bottomBarView.leadingBarButtonItems = [shareButton, calendarButton]
    view.addSubview(bottomBarView)
    collectionView.backgroundColor = .white

    setupConstraints()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    setupConstraints()
  }

  func setupConstraints() {
    let views = [
      "bottomBarView": bottomBarView
    ] as [String: Any]

    if bottomBarConstraint == nil {
      var constraints =
        NSLayoutConstraint.constraints(withVisualFormat: "H:|[bottomBarView]|",
                                       options: [],
                                       metrics: nil,
                                       views: views)
      bottomBarConstraint = bottomBarView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor,
                                                                  constant: 0)

      if let constraint = bottomBarConstraint {
        constraints += [constraint]
      }
      constraints += [
        bottomBarView.heightAnchor.constraint(equalToConstant: 96)
      ]

      NSLayoutConstraint.activate(constraints)
    }

    setup3DTouch()
  }

  override func setupAppBar() -> MDCAppBarViewController {
    let appBar = super.setupAppBar()

    appBar.headerStackView.bottomBar = youtubePlayerView

    let model = viewModel.scheduleEventDetailsViewModel
    if model.shouldDisplayVideoplayer {
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

      NSLayoutConstraint.activate(constraints)
    }

    appBar.headerView.insertSubview(headerImageView, at: 0)

    let constraints = [
      NSLayoutConstraint(item: headerImageView, attribute: .top,
                         relatedBy: .equal,
                         toItem: appBar.headerView, attribute: .top,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: headerImageView, attribute: .left,
                         relatedBy: .equal,
                         toItem: appBar.headerView, attribute: .left,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: headerImageView, attribute: .right,
                         relatedBy: .equal,
                         toItem: appBar.headerView, attribute: .right,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: headerImageView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: appBar.headerView, attribute: .bottom,
                         multiplier: 1, constant: 0)
    ]
    appBar.headerView.addConstraints(constraints)

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
    collectionView?.register(MDCCollectionViewTextCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)

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
    shareButton.accessibilityLabel =
        NSLocalizedString("Share this session",
                          comment: "Accessibility label for sharing button.")
    return shareButton
  }

  private lazy var calendarButton: UIBarButtonItem = {
    let image = UIImage(named: "ic_calendar")
    let button = UIBarButtonItem(image: image,
                                 style: .plain,
                                 target: self,
                                 action: #selector(calendarTapped(_:)))
    button.tintColor = LayoutConstants.headerColor
    button.accessibilityLabel =
        NSLocalizedString("Add session to calendar",
                          comment: "Accessibility button label for adding an event to calendar.")
    return button
  }()

  func setupBottomBarView() -> MDCBottomAppBarView {
    bottomBarView = MDCBottomAppBarView()
    bottomBarView.translatesAutoresizingMaskIntoConstraints = false
    bottomBarView.floatingButtonPosition = .trailing
    bottomBarView.floatingButton.addTarget(self,
                                           action: #selector(toggleFavourite),
                                           for: .touchUpInside)
    return bottomBarView
  }

  fileprivate func updateFromViewModel() {
    let model = viewModel.scheduleEventDetailsViewModel
    let button = bottomBarView.floatingButton
    button.backgroundColor = model.bookmarkButtonBackgroundColor
    button.setImage(model.bookmarkButtonImage, for: .normal)
    button.accessibilityLabel = model.bookmarkButtonAccessibilityLabel
    button.isHidden = !model.isBookmarkable
    calendarButton.isEnabled = SignIn.sharedInstance.currentUser != nil

    youtubeURL = model.youtubeURL
    headerImageView.image = viewModel.headerImageForRoom()
    headerImageView.isHidden = viewModel.scheduleEventDetailsViewModel.shouldDisplayVideoplayer
  }

  private func registerForTimeZoneChanges() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(timeZoneDidChange(_:)),
                                           name: .timezoneUpdate,
                                           object: nil)
  }

  @objc private func timeZoneDidChange(_ notification: Any) {
    updateFromViewModel()
    collectionView.reloadData()
  }

// MARK: - Analytics

  @objc override var screenName: String? {
    let title = viewModel.scheduleEventDetailsViewModel.title
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
    let model = viewModel.scheduleEventDetailsViewModel
    if model.shouldDisplayVideoplayer {
      return StylingConstants.minHeaderHeightWithVideoplayer
          + UIApplication.shared.statusBarFrame.height
    }
    return StylingConstants.minHeaderHeight + UIApplication.shared.statusBarFrame.height
  }

  @objc override var maxHeaderHeight: CGFloat {
    let model = viewModel.scheduleEventDetailsViewModel
    if model.shouldDisplayVideoplayer {
      return StylingConstants.maxHeaderHeightWithVideoplayer
          + UIApplication.shared.statusBarFrame.height
    }
    return StylingConstants.maxHeaderHeight + UIApplication.shared.statusBarFrame.height
  }

  @objc override var additionalBottomContentInset: CGFloat {
    return 58
  }
}

// MARK: - Actions
extension SessionDetailsViewController {
  @objc private func shareAction(_ sender: Any) {
    // There's something going on that prevents our bar button item from having a nonnil
    // `view` property (private API), which cause UIPopoverPresentationController to crash
    // on iPads. This is the much more disgusting workaround.
    let rect = CGRect(x: 24, y: 54, width: 24, height: 24)
    let sourceView = bottomBarView
    viewModel.shareSession(sourceView: sourceView, sourceRect: rect)
  }

  @objc private func calendarTapped(_ sender: Any) {
    viewModel.addToCalendar { error in
      var snackBarMessage: MDCSnackbarMessage
      if let error = error {
        if (error as NSError).domain == GoogleCalendarSessionAdder.errorDomain {
          snackBarMessage = MDCSnackbarMessage(text: error.localizedDescription)
        } else {
          let localizedGenericError = NSLocalizedString(
            "Error saving event to calendar",
            comment: "Generic failure message when saving event to calendar"
          )
          snackBarMessage = MDCSnackbarMessage(text: localizedGenericError)
        }
      } else {
        guard let emailAddress = SignIn.sharedInstance.currentUser?.email else { return }
        let localizedSuccessMessage = NSLocalizedString(
          "Added event to calendar for \(emailAddress)",
          comment: "Localized format string for success message when adding an event to calendar"
        )
        snackBarMessage = MDCSnackbarMessage(text: localizedSuccessMessage)
      }

      MDCSnackbarManager.show(snackBarMessage)
    }
  }

  @objc private func mapAction() {
    viewModel.openMap()
  }

  @objc private func toggleFavourite() {
    viewModel.toggleBookmark()
    let title = viewModel.scheduleEventDetailsViewModel.title
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.uiEvent,
      AnalyticsParameterItemID: title,
      AnalyticsParameters.uiAction: AnalyticsParameters.bookmarked
    ])
  }
}

// MARK: - UICollectionView Layout

extension SessionDetailsViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    let measureCell: MDCCollectionViewCell = {
      if indexPath.section == 0 {
        return measureMainInfoCell
      }
      else {
        return measureSpeakerCell
      }
    }()

    populateCell(cell: measureCell, forItemAt: indexPath)
    return measureCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
  }

}

// MARK: - UICollectionView DataSource

extension SessionDetailsViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    switch section {
    case 0:
      return 1
    case 1:
      return viewModel.scheduleEventDetailsViewModel.speakers.count
    case _:
      return 0
    }
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch indexPath.section {
    case 0:
      let cell: SessionDetailsCollectionViewMainInfoCell =
          collectionView.dequeueReusableCell(for: indexPath)
      populateCell(cell: cell, forItemAt: indexPath)
      return cell
    case 1:
      let cell: SessionDetailsCollectionViewSpeakerCell =
          collectionView.dequeueReusableCell(for: indexPath)
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
    let view = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: MDCCollectionViewTextCell.self.reuseIdentifier(),
      for: indexPath
    )
    if let cell = view as? MDCCollectionViewTextCell {
      switch indexPath.section {
      case 1:
        cell.textLabel?.text = NSLocalizedString("Speakers",
                                                 comment: "Header for speakers in this session")
        cell.textLabel?.font = LayoutConstants.headerFont()
        cell.textLabel?.textColor = LayoutConstants.headerColor

      case _:
        break
      }
    }
    return view
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    if section == 0 {
      return LayoutConstants.headerSize
    } else {
      if collectionView.dataSource?.collectionView(collectionView,
                                                   numberOfItemsInSection: section) == 0 {
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
      cell.viewModel = self.viewModel.scheduleEventDetailsViewModel.speakers[indexPath.row]
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath)

    if let cell = cell as? SessionDetailsCollectionViewSpeakerCell {
      cell.viewModel?.selectSpeaker(speaker: (cell.viewModel?.speaker)!)
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    return collectionView.cellForItem(at: indexPath)
        as? SessionDetailsCollectionViewSpeakerCell != nil
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

      return viewModel.detailsViewController(indexPath)
    }
    return nil
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                         commit viewControllerToCommit: UIViewController) {
    self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
  }

}

// MARK: - 3D Touch action items

extension SessionDetailsViewController {
  override var previewActionItems: [UIPreviewActionItem] {
    let eventDetailsViewModel = viewModel.scheduleEventDetailsViewModel
    guard eventDetailsViewModel.isBookmarkable else { return [] }

    let title = eventDetailsViewModel.bookmarkPreviewActionTitle
    let actionToogleBookmark = UIPreviewAction(title: title, style: .default) { (_, _) in
      self.viewModel.toggleBookmark()
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
    let model = viewModel.scheduleEventDetailsViewModel
    guard model.shouldDisplayVideoplayer else { return }

    guard scrollView == appBar.headerView.trackingScrollView else { return }

    let minimumHeight = appBar.headerView.minimumHeight
    let offset = scrollView.contentOffset.y

    let remainingheight = max(0, -offset - minimumHeight)
    let height = min(ScrollingConstants.cutOffHeight, remainingheight)
    let alpha = height / ScrollingConstants.cutOffHeight
    appBar.headerStackView.topBar?.alpha = alpha
  }

}
