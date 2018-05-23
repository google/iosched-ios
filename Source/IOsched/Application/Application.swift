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
import Domain
import Platform

final class Application: NSObject {

  // MARK: - Constants

  private enum TabTitles {
    static let schedule = "Schedule"
    static let map = "Map"
    static let info = "Info"
  }

  private enum TabIcons {
    static let schedule = UIImage(named: "ic_schedule")
    static let map = UIImage(named: "ic_map")
    static let info = UIImage(named: "ic_info_outline")
  }

  private enum LayoutConstants {
    static let tabBarTintColor = MDCPalette.indigo.accent200
    static let tabBarTextSize: CGFloat = 10.0
    static let tabBarVerticalOffset: CGFloat = -4.0
  }

  // MARK: - Singleton

  lazy var serviceLocator: ServiceLocator = {
    return DefaultServiceLocator.sharedInstance
  }()

  lazy var analytics: AnalyticsWrapper = {
    return AnalyticsWrapper(userState: self.serviceLocator.userState)
  }()

  static let sharedInstance = Application()
  private override init() {
    super.init()
  }

  // MARK: - Main UI controller setup

  lazy var rootNavigator: RootNavigator = {
    let rootNavigator = RootNavigator(self)
    return rootNavigator
  }()

  lazy var scheduleViewController: UINavigationController = {
    let navigationController = UINavigationController()
    navigationController.setNavigationBarHidden(true, animated: false)
    navigationController.tabBarItem = UITabBarItem(title: TabTitles.schedule, image: TabIcons.schedule, tag: 0)

    return navigationController
  }()

  lazy var scheduleNavigator: ScheduleNavigator = {
    let navigator = DefaultScheduleNavigator(serviceLocator: self.serviceLocator, rootNavigator: self.rootNavigator, navigationController: self.scheduleViewController)
    return navigator
  }()

  lazy var mapViewController: MapViewController = {
    let mapViewModel = MapViewModel(conferenceDataSource: self.serviceLocator.conferenceDataSource)
    let viewController = MapViewController(viewModel: mapViewModel)
    viewController.tabBarItem = UITabBarItem(title: TabTitles.map, image: TabIcons.map, tag: 0)
    return viewController
  }()

  lazy var infoViewController: InfoViewController = {
    let viewModel = SettingsViewModel(userState: self.serviceLocator.userState)
    let viewController = InfoViewController(settingsViewModel: viewModel)
    viewController.tabBarItem = UITabBarItem(title: TabTitles.info, image: TabIcons.info, tag: 0)
    return viewController
  }()

  lazy var tabBarController: UITabBarController = {
    let tabBarController = UITabBarController()
    tabBarController.viewControllers = [
      self.scheduleViewController,
      self.mapViewController,
      self.infoViewController
    ]

    self.scheduleNavigator.navigateToStart()

    tabBarController.viewControllers?.forEach { controller in
      let font = UIFont.systemFont(ofSize: LayoutConstants.tabBarTextSize, weight: UIFont.Weight.medium)
      let attributes = [ NSAttributedStringKey.font: font]
      controller.tabBarItem.setTitleTextAttributes(attributes, for: .normal)
      controller.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: LayoutConstants.tabBarVerticalOffset)
    }
    tabBarController.tabBar.tintColor = LayoutConstants.tabBarTintColor
    tabBarController.delegate = self
    return tabBarController
  }()

  // MARK: - Onboarding flow controller setup

  lazy var onboardingPageViewController: UIPageViewController? = {
    let appearance = UIPageControl.appearance()
    appearance.pageIndicatorTintColor = UIColor(hex: "#dddddd")
    appearance.currentPageIndicatorTintColor = UIColor(hex: "#bdbdbd")
    appearance.backgroundColor = .white
    let pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                  navigationOrientation: .horizontal,
                                                  options: nil)
    pageViewController.view.backgroundColor = .white
    let navigator = DefaultOnboardingNavigator(serviceLocator: self.serviceLocator,
                                               pageViewController: pageViewController)
    navigator.onOnboardingCompleted {
      self.activateMainInterface()
    }
    navigator.navigateToStart()

    return pageViewController
  }()

  // MARK: - Manage UI flow and switching from onboarding to the main flow

  func activateMainInterface() {
    self.window?.rootViewController = self.tabBarController

    // Release the onboarding flow so it can be deallocated.
    onboardingPageViewController?.view.removeFromSuperview()
    onboardingPageViewController?.dismiss(animated: false, completion: nil)
    onboardingPageViewController = nil

    self.window?.makeKeyAndVisible()

    // Optionally, use this to transition from onboarding to main navigation.
    // Note, however, that this will result in the snackbar transition to be less beautiful
//    UIView.transition(with: window!, duration: 0.5, options: .transitionCrossDissolve, animations: {
//      self.window?.rootViewController = self.tabBarController
//    })
  }

  var window: UIWindow?

  func configureMainInterface(in window: UIWindow?) {
    self.window = window
    registerForModelUpdates()
    if shouldDisplayOnboarding() {
      window?.rootViewController = onboardingPageViewController
    }
    else {
      self.window?.rootViewController = self.tabBarController
    }
  }

  private func registerForModelUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(registerImFeelingLuckyShortcut),
                                           name: .conferenceUpdate,
                                           object: nil)
  }

}

extension Application {
  fileprivate func shouldDisplayOnboarding() -> Bool {
    let userState = self.serviceLocator.userState
    return userState.shouldDisplayOnboarding
  }
}

extension Application: UITabBarControllerDelegate {

  func tabBarController(_ tabBarController: UITabBarController,
                        didSelect viewController: UIViewController) {
    let selected: String?

    switch viewController {
    case scheduleViewController:
      selected = AnalyticsParameters.schedule
    case mapViewController:
      selected = AnalyticsParameters.map
    case infoViewController:
      selected = AnalyticsParameters.info

    case _:
      selected = nil
    }

    guard let itemID = selected else { return }
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.uiEvent,
      AnalyticsParameters.uiAction: AnalyticsParameters.primaryNavClick,
      AnalyticsParameterItemID: itemID
    ])
  }

}

class RootNavigator {

  let application: Application
  init(_ application: Application) {
    self.application = application
  }

  func navigateToSchedule(day: Int? = nil) {
    application.tabBarController.selectedViewController = application.scheduleViewController
    if let day = day {
      application.scheduleNavigator.navigateToDay(day: day)
    }
  }

  func navigateToMap(roomId: String?) {
    application.tabBarController.selectedViewController = application.mapViewController
    application.mapViewController.select(roomId: roomId)
  }

  public func navigateToEventInfo() {
    application.tabBarController.selectedViewController = application.infoViewController
    application.infoViewController.showEventInfo()
  }
}
