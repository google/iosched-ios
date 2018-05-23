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

class BaseCollectionViewController: MDCCollectionViewController {

  lazy var appBar: MDCAppBar = self.setupAppBar()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    enableSwipeBackGesture()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Application.sharedInstance.analytics
      .setScreenName("\(type(of: self))", screenClass: "\(type(of: self))")

    if UIAccessibilityIsVoiceOverRunning() {
      // Brittle, but works around something else hijacking UIAccessibility focus
      // when the app is launched.
      DispatchQueue.main.async {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                        self.titleLabel)
      }
    }
    logPresentationEvent()
  }

// MARK: - View setup

  private enum Constants {
    static let titleHeight: CGFloat = 24.0
    static let titleFontName = "Product Sans"
    static let titleFont = UIFont(name: Constants.titleFontName, size: Constants.titleHeight)
  }

  func setupViews() {
    appBar.headerViewController.didMove(toParentViewController: self)
    appBar.addSubviewsToParent()

    setupTracking()
  }

  func setupAppBar() -> MDCAppBar {
    let appBar = MDCAppBar()
    self.addChildViewController(appBar.headerViewController)

    let headerView = appBar.headerViewController.headerView
    headerView.backgroundColor = headerBackgroundColor
    headerView.minimumHeight = minHeaderHeight
    headerView.maximumHeight = maxHeaderHeight

    appBar.navigationBar.tintColor = headerForegroundColor

    var attributes: [NSAttributedStringKey: Any] =
      [ NSAttributedStringKey.foregroundColor: headerForegroundColor]
    let font = Constants.titleFont
    if let font = font {
      attributes[NSAttributedStringKey.font] = font
    }
    appBar.navigationBar.titleTextAttributes = attributes

    return appBar
  }

  func setHeaderBackgroundColor(color: UIColor) {
    let headerView = appBar.headerViewController.headerView
    headerView.backgroundColor = color
  }

  func setHeaderForegroundColor(color: UIColor) {
    appBar.navigationBar.tintColor = color

    var attributes: [NSAttributedStringKey: Any] = [ NSAttributedStringKey.foregroundColor: color]
    let font = Constants.titleFont
    if let font = font {
      attributes[NSAttributedStringKey.font] = font
    }
    appBar.navigationBar.titleTextAttributes = attributes
  }

  func setupTracking() {
    appBar.headerViewController.headerView.trackingScrollView = self.collectionView
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    adjustContentInset()
  }

  func adjustContentInset() {
    if let collectionView = collectionView, let tabBarController = tabBarController {
      var inset = collectionView.contentInset
      let targetBottomInset = tabBarController.tabBar.bounds.height + additionalBottomContentInset
      if inset.bottom < targetBottomInset {
        inset.bottom += targetBottomInset
        collectionView.contentInset = inset
        collectionView.scrollIndicatorInsets = inset
      }
    }
  }

  var titleLabel: UILabel? {
    for view in appBar.navigationBar.subviews {
      if let label = view as? UILabel {
        return label
      }
    }
    return nil
  }

// MARK: - UIGestureRecognizerDelegate
// Enable swipe back gesture
  func enableSwipeBackGesture() {
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
  }

  override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

// MARK: - ViewControllerStylable
  private enum StylingConstants {
    static let minHeaderHeight: CGFloat = 105
    static let maxHeaderHeightDiff: CGFloat = 55
    static let headerBackgroundColor = UIColor.white
    static let headerForegroundColor = UIColor(hex: "#424242")
  }

  var minHeaderHeight: CGFloat {
    let height: CGFloat
    if #available(iOS 11, *) {
      height = tabBarController?.view.safeAreaInsets.top ?? 0
    } else {
      height = tabBarController?.topLayoutGuide.length ?? 0
    }
    return StylingConstants.minHeaderHeight + height
  }

  var maxHeaderHeight: CGFloat {
    return minHeaderHeight + StylingConstants.maxHeaderHeightDiff
  }

  var headerBackgroundColor: UIColor {
    return StylingConstants.headerBackgroundColor
  }

  var headerForegroundColor: UIColor {
    return StylingConstants.headerForegroundColor
  }

  var tabBarTintColor: UIColor? {
    return MDCPalette.indigo.accent200
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return headerForegroundColor == UIColor.white
      ? .lightContent
      : .default
  }

  // TODO make this more generic, so it will work for animated headers as well
  var logoFileName: String? {
    return nil
  }

  var additionalBottomContentInset: CGFloat {
    return 0
  }

// MARK: - UIScrollViewDelegate

  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView == self.appBar.headerViewController.headerView.trackingScrollView {
      self.appBar.headerViewController.headerView.trackingScrollDidScroll()
    }
  }

  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if scrollView == self.appBar.headerViewController.headerView.trackingScrollView {
      self.appBar.headerViewController.headerView.trackingScrollDidEndDecelerating()
    }
  }

  override func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                         willDecelerate decelerate: Bool) {
    let headerView = self.appBar.headerViewController.headerView
    if scrollView == headerView.trackingScrollView {
      headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
    }
  }

  override func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let headerView = self.appBar.headerViewController.headerView
    if scrollView == headerView.trackingScrollView {
      headerView.trackingScrollWillEndDragging(withVelocity: velocity,
                                               targetContentOffset: targetContentOffset)
    }
  }

// MARK: Analytics

  var screenName: String? {
    return nil
  }

  fileprivate func logPresentationEvent(withLogger logger: AnalyticsWrapper = Application.sharedInstance.analytics) {
    guard let screen = screenName else { return }
    logger.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.screen,
      AnalyticsParameterItemID: screen
    ])
  }

}
