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

  lazy var appBar: MDCAppBarViewController = self.setupAppBar()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    enableSwipeBackGesture()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Application.sharedInstance.analytics
      .setScreenName("\(type(of: self))", screenClass: "\(type(of: self))")

    if UIAccessibility.isVoiceOverRunning {
      // Brittle, but works around something else hijacking UIAccessibility focus
      // when the app is launched.
      DispatchQueue.main.async {
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged,
                             argument: self.titleLabel)
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
    addChild(appBar)
    view.addSubview(appBar.view)
    appBar.didMove(toParent: self)

    setupTracking()
  }

  func setupAppBar() -> MDCAppBarViewController {
    let appBar = MDCAppBarViewController()

    let headerView = appBar.headerView
    headerView.backgroundColor = headerBackgroundColor
    headerView.minimumHeight = minHeaderHeight
    headerView.maximumHeight = maxHeaderHeight

    appBar.navigationBar.tintColor = headerForegroundColor
    appBar.navigationBar.uppercasesButtonTitles = false
    appBar.navigationBar.titleViewLayoutBehavior = .fill

    var attributes: [NSAttributedString.Key: Any] =
      [NSAttributedString.Key.foregroundColor: headerForegroundColor]
    let font = Constants.titleFont
    if let font = font {
      attributes[NSAttributedString.Key.font] = font
    }
    appBar.navigationBar.titleTextAttributes = attributes
    appBar.navigationBar.titleViewLayoutBehavior = .center

    return appBar
  }

  func setHeaderBackgroundColor(color: UIColor) {
    let headerView = appBar.headerView
    headerView.backgroundColor = color
  }

  func setHeaderForegroundColor(color: UIColor) {
    appBar.navigationBar.tintColor = color

    var attributes: [NSAttributedString.Key: Any] = [ NSAttributedString.Key.foregroundColor: color]
    let font = Constants.titleFont
    if let font = font {
      attributes[NSAttributedString.Key.font] = font
    }
    appBar.navigationBar.titleTextAttributes = attributes
  }

  func setupTracking() {
    appBar.headerView.trackingScrollView = collectionView
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
    navigationController?.interactivePopGestureRecognizer?.delegate = self
  }

  override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

// MARK: - ViewControllerStylable
  private enum StylingConstants {
    static let minHeaderHeight: CGFloat = 104
    static let headerBackgroundColor = UIColor.white
    static let headerForegroundColor = UIColor(hex: "#202124")
  }

  var minHeaderHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.height + StylingConstants.minHeaderHeight
  }

  var maxHeaderHeight: CGFloat {
    return minHeaderHeight
  }

  var headerBackgroundColor: UIColor {
    return StylingConstants.headerBackgroundColor
  }

  var headerForegroundColor: UIColor {
    return StylingConstants.headerForegroundColor
  }

  var tabBarTintColor: UIColor? {
    return UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return headerForegroundColor == UIColor.white
      ? .lightContent
      : .default
  }

  var logoFileName: String? {
    return nil
  }

  var additionalBottomContentInset: CGFloat {
    return 0
  }

// MARK: - UIScrollViewDelegate

  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView == appBar.headerView.trackingScrollView {
      appBar.headerView.trackingScrollDidScroll()
    }
  }

  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if scrollView == appBar.headerView.trackingScrollView {
      appBar.headerView.trackingScrollDidEndDecelerating()
    }
  }

  override func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                         willDecelerate decelerate: Bool) {
    let headerView = appBar.headerView
    if scrollView == headerView.trackingScrollView {
      headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
    }
  }

  override func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let headerView = appBar.headerView
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
