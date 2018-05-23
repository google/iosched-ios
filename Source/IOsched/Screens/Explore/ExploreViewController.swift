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

import UIKit
import ArWebView

// swiftlint:disable identifier_name
public func IsExploreModeSupported() -> Bool {
  if #available(iOS 11, *) {
#if targetEnvironment(simulator)
    return true
#else
    return GARArStatus.sharedInstance.arKitReady
#endif
  } else {
    return false
  }
}
// swiftlint:enable identifier_name

class ExploreViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate {

  @available(iOS 11, *)
  private lazy var arWebView: GARArWebView! = initializeWebView()

  private lazy var notSupportedView = ExploreNotSupportedView(frame: view.frame)
  private lazy var offlineView = ExploreOfflineView(frame: view.frame)

  private let reservationDataSource: RemoteReservationDataSource
  private let bookmarkDataSource: RemoteBookmarkDataSource
  private let sessionsDataSource: LazyReadonlySessionsDataSource
  private let debugStatusFetcher = DebugModeStatusFetcher()

  private static let dateFormatter: DateFormatter = {
    let formatter = TimeZoneAwareDateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("MMMdd")
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

  private static let timeFormatter: DateFormatter = {
    let formatter = TimeZoneAwareDateFormatter()
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

  public init(reservations: RemoteReservationDataSource,
              bookmarks: RemoteBookmarkDataSource,
              sessions: LazyReadonlySessionsDataSource) {
    reservationDataSource = reservations
    bookmarkDataSource = bookmarks
    sessionsDataSource = sessions
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func jsonForReservedAndBookmarkedSessions() -> String {
    sessionsDataSource.update()
    var userAgenda: [Session] = []
    for reservedSession in reservationDataSource.reservedSessions where
      reservedSession.status != .none {
      if let session = sessionsDataSource[reservedSession.id] {
        userAgenda.append(session)
      }
    }
    for bookmarkedSessionID in bookmarkDataSource.bookmarks.keys {
      // Don't duplicate reserved/waitlisted and bookmarked sessions here.
      if reservationDataSource.reservationStatus(for: bookmarkedSessionID) == .none,
          let session = sessionsDataSource[bookmarkedSessionID] {
        userAgenda.append(session)
      }
    }

    var list: [[String: Any]] = []
    for session in userAgenda {
      let dateString = ExploreViewController.dateFormatter.string(from: session.startTimestamp)
      let timeString = ExploreViewController.timeFormatter.string(from: session.startTimestamp)
      let startTimestamp = Int(session.startTimestamp.timeIntervalSince1970.rounded())

      list.append([
        "name": session.title,
        "location": session.roomName,
        "day": dateString,
        "time": timeString,
        "timestamp": startTimestamp,
        "description": session.detail
      ])
    }

    let object = ["schedule": list]
    let json = try? JSONSerialization.data(withJSONObject: object, options: [])
    let jsonString = json.flatMap { String(data: $0, encoding: .unicode) }
    return jsonString ?? "{\"schedule\":[]}"
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if #available(iOS 11, *) {
      if IsExploreModeSupported() {
        setupWebView()
      } else {
        setupNotSupportedView()
      }
    } else {
      setupNotSupportedView()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if #available(iOS 11, *) {
      UIApplication.shared.isIdleTimerDisabled = true
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    UIApplication.shared.isIdleTimerDisabled = false
    if #available(iOS 11, *) {
      showOverlay()
    }
  }

  @available(iOS 11, *)
  private func initializeWebView() -> GARArWebView {
    let configuration = WKWebViewConfiguration()
    configuration.allowsInlineMediaPlayback = true
    configuration.mediaTypesRequiringUserActionForPlayback = []
    configuration.websiteDataStore = WKWebsiteDataStore.default()
    let webView = WKWebView(frame: view.bounds, configuration: configuration)

    let arWebView = GARArWebView(frame: view.bounds, webView: webView)
    arWebView.translatesAutoresizingMaskIntoConstraints = false
    arWebView.webView.navigationDelegate = self
    arWebView.webView.scrollView.isScrollEnabled = false
    arWebView.webView.scrollView.minimumZoomScale = 1
    arWebView.webView.scrollView.maximumZoomScale = 1
    arWebView.webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    arWebView.webView.scrollView.delegate = self
    return arWebView
  }

  @available(iOS 11, *)
  private func setupWebView() {

    view.addSubview(arWebView)

    removeScrollGestureRecognizers()
    setupWebViewConstraints()
    registerForTimeZoneChanges()

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(refresh(_:)),
                                           name: UIApplication.willEnterForegroundNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didEnterBackgroundNotification(_:)),
                                           name: UIApplication.didEnterBackgroundNotification,
                                           object: nil)
  }

  private func setupNotSupportedView() {
    notSupportedView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(notSupportedView)

    let constraints = [
      NSLayoutConstraint(item: notSupportedView, attribute: .top,
                         relatedBy: .equal,
                         toItem: view, attribute: .top,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: notSupportedView, attribute: .left,
                         relatedBy: .equal,
                         toItem: view, attribute: .left,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: notSupportedView, attribute: .right,
                         relatedBy: .equal,
                         toItem: view, attribute: .right,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: notSupportedView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: view, attribute: .bottom,
                         multiplier: 1, constant: 0)
    ]

    view.addConstraints(constraints)
  }

  private func setupOfflineView() {
    offlineView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(offlineView)

    let constraints = [
      NSLayoutConstraint(item: offlineView, attribute: .top,
                         relatedBy: .equal,
                         toItem: view, attribute: .top,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: offlineView, attribute: .left,
                         relatedBy: .equal,
                         toItem: view, attribute: .left,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: offlineView, attribute: .right,
                         relatedBy: .equal,
                         toItem: view, attribute: .right,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: offlineView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: view, attribute: .bottom,
                         multiplier: 1, constant: 0)
    ]

    view.addConstraints(constraints)
  }

  @available(iOS 11, *)
  private func reloadWebView() {
    let url = URL(string: "https://sp-io2019.appspot.com/")!
    let request = URLRequest(url: url,
                             cachePolicy: .reloadRevalidatingCacheData,
                             timeoutInterval: 100)
    arWebView?.load(request)
  }

  @available(iOS 11, *)
  @objc private func refresh(_ sender: Any) {
    reloadWebView()
  }

  @available(iOS 11, *)
  @objc private func didEnterBackgroundNotification(_ sender: Any) {
    showOverlay()
  }

  @available(iOS 11, *)
  private func showOverlay() {
    let script = "window.app && window.app.addIntroOverlay && window.app.addIntroOverlay();"
    arWebView.webView.evaluateJavaScript(script) { (result, error) in
      guard error == nil else {
        print(error!)
        return
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if #available(iOS 11, *), IsExploreModeSupported() {
      offlineView.removeFromSuperview()
      reloadWebView()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @available(iOS 11, *)
  private func setupWebViewConstraints() {
    let constraints = [
      NSLayoutConstraint(item: arWebView,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: view,
                         attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: arWebView,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: view,
                         attribute: .top,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: arWebView,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: view,
                         attribute: .right,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: arWebView,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: bottomLayoutGuide,
                         attribute: .top,
                         multiplier: 1,
                         constant: 0)
    ]

    view.addConstraints(constraints)
  }

  // MARK: - WKNavigationDelegate

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    let agendaJSON = jsonForReservedAndBookmarkedSessions()
    let javascript = "var object = \(agendaJSON); window.app.sendIOAppUserAgenda(object);"
    webView.evaluateJavaScript(javascript) { (result, error) in
      if let error = error {
        print("evaluateJavascript error: \(error)")
      }
      if let result = result {
        print(result)
      }
    }
    debugStatusFetcher.fetchDebugModeEnabled { status in
      if status {
        webView.evaluateJavaScript("window.app.setDebugUser();") { (_, error) in
          if let error = error {
            print("Error enabling debug mode: \(error)")
          }
        }
      }
    }
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    setupOfflineView()
  }

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    if #available(iOS 11, *) {
      arWebView.webView(webView, didCommit: navigation)
    }
  }

  @available(iOS 11, *)
  func removeScrollGestureRecognizers() {
    // hack
    for recognizer in arWebView.webView.scrollView.gestureRecognizers ?? [] {
      recognizer.isEnabled = false
      arWebView.webView.scrollView.removeGestureRecognizer(recognizer)
    }
  }

  // MARK: - UIScrollViewDelegate

  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    if #available(iOS 11, *), IsExploreModeSupported() {
      removeScrollGestureRecognizers()
    }
  }

  func registerForTimeZoneChanges() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(timeZoneDidChange(_:)),
                                           name: .timezoneUpdate,
                                           object: nil)
  }

  @objc private func timeZoneDidChange(_ notification: Any) {
    if #available(iOS 11, *) {
      reloadWebView()
    }
  }

}
