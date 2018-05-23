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

/// A class for representing general application-level state objects, like the
/// global UITabBarController instance. This is a good place to hang immutable state
/// (such as tab bar titles or icons).
final class Application: NSObject {

  // MARK: - Constants

  private enum TabTitles {
    static let home = NSLocalizedString("Home", comment: "Title of the home screen")
    static let schedule = NSLocalizedString(
      "Schedule",
      comment: "Title of the Schedule screen. May also appear in search results."
    )
    static let map = NSLocalizedString("Map", comment: "Title of the map screen")
    static let info = NSLocalizedString(
      "Info",
      comment: "Title of the Info screen. May also appear in search results."
    )
    static let explore = NSLocalizedString("Explore I/O", comment: "Title of the Explore screen.")
    static let codelabs = NSLocalizedString(
      "Codelabs",
      comment: "Title of the Codelabs screen. May also appear in search results."
    )
    static let settings = NSLocalizedString("Settings", comment: "Title of the settings screen.")
    static let search = NSLocalizedString("Search", comment: "Title of the search screen.")
  }

  private enum TabIcons {
    static let schedule = UIImage(named: "ic_schedule")
    static let map = UIImage(named: "ic_map")
    static let info = UIImage(named: "ic_info_outline")
    static let explore = UIImage(named: "ic_explore")
    static let home = UIImage(named: "ic_home")
    static let settings = UIImage(named: "ic_settings")
    static let codelabs = UIImage(named: "ic_codelabs")
    static let search = UIImage(named: "ic_search")
  }

  private enum LayoutConstants {
    static let tabBarTintColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
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

  var shouldDisplayExploreViewController: Bool {
    guard IsExploreModeSupported() else { return false }
    guard serviceLocator.userState.isUserSignedIn else { return true }
    return serviceLocator.userState.isUserRegistered
  }

  // MARK: - Main UI controller setup

  private func containingNavigationController(for controller: UIViewController?,
                                              with item: UITabBarItem) -> UINavigationController {
    let navigationController = UINavigationController()
    navigationController.setNavigationBarHidden(true, animated: false)
    navigationController.tabBarItem = item
    if let controller = controller {
      navigationController.viewControllers = [controller]
    }
    return navigationController
  }

  lazy var rootNavigator: RootNavigator = {
    return RootNavigator(self)
  }()

  lazy var scheduleNavigationController: UINavigationController = {
    let tabBarItem = UITabBarItem(title: TabTitles.schedule,
                                  image: TabIcons.schedule, tag: 0)
    return containingNavigationController(for: nil, with: tabBarItem)
  }()

  lazy var scheduleNavigator: ScheduleNavigator = {
    let navigator = DefaultScheduleNavigator(serviceLocator: serviceLocator,
                                             rootNavigator: rootNavigator,
                                             navigationController: scheduleNavigationController)
    return navigator
  }()

  lazy var mapViewController: MapViewController = MapViewController(viewModel: MapViewModel())

  lazy var mapNavigationController: UINavigationController = {
    let tabBarItem = UITabBarItem(title: TabTitles.map, image: TabIcons.map, tag: 0)
    return containingNavigationController(for: mapViewController, with: tabBarItem)
  }()

  lazy var infoViewController: InfoViewController = {
    let viewModel = SettingsViewModel(userState: serviceLocator.userState)
    let viewController = InfoViewController(settingsViewModel: viewModel)
    viewController.tabBarItem = UITabBarItem(title: TabTitles.info, image: TabIcons.info, tag: 0)
    return viewController
  }()

  lazy var infoNavigationController: UINavigationController = {
    return containingNavigationController(for: infoViewController,
                                          with: infoViewController.tabBarItem)
  }()

  /* TODO(morganchen): Implement codelabs
  lazy var codelabsViewController: CodelabsViewController = {
    let controller = CodelabsViewController()
    controller.tabBarItem = UITabBarItem(title: TabTitles.codelabs, image: TabIcons.codelabs, tag: 0)
    return controller
  }()

  lazy var codelabsNavigationController: UINavigationController = {
    return containingNavigationController(for: codelabsViewController,
                                          with: codelabsViewController.tabBarItem)
  }()
  */

  lazy var exploreViewController: ExploreViewController = {
    let controller = ExploreViewController(reservations: serviceLocator.reservationDataSource,
                                           bookmarks: serviceLocator.bookmarkDataSource,
                                           sessions: serviceLocator.sessionsDataSource)
    return controller
  }()

  lazy var exploreNavigationController: UINavigationController = {
    let tabBarItem = UITabBarItem(title: TabTitles.explore, image: TabIcons.explore, tag: 0)
    return containingNavigationController(for: exploreViewController, with: tabBarItem)
  }()

  lazy var homeViewController: HomeViewController = {
    return HomeViewController(serviceLocator: serviceLocator,
                              navigator: rootNavigator)
  }()

  lazy var homeNavigationController: UINavigationController = {
    let item = UITabBarItem(title: TabTitles.home, image: TabIcons.home, tag: 0)
    return containingNavigationController(for: homeViewController, with: item)
  }()

  lazy var profileViewController: UserAccountInfoViewController = {
    let viewModel = UserAccountInfoViewModel(userState: serviceLocator.userState)
    let settingsViewModel = SettingsViewModel(userState: self.serviceLocator.userState)
    let viewController = UserAccountInfoViewController(viewModel: viewModel,
                                                       settingsViewModel: settingsViewModel)
    viewController.tabBarItem = UITabBarItem(title: TabTitles.settings,
                                             image: TabIcons.settings,
                                             tag: 0)
    return viewController
  }()

  lazy var agendaViewController = AgendaViewController()

  lazy var sideNavigationController: BottomSheetContainerViewController = {

    let tabControllers: [UINavigationController]
    let rightDrawerItems: [UIViewController]

    // TODO(b/124778329): Once codelabs are implemented, move Info
    // to the overflow nav and put codelabs in the bottom tab.
    tabControllers = [
      homeNavigationController,
      scheduleNavigationController,
      exploreNavigationController,
      mapNavigationController
    ]
    rightDrawerItems = [
      profileViewController,
      infoViewController,
      agendaViewController
    ]

    tabBarController.viewControllers = tabControllers
    tabBarController.tabBar.isTranslucent = false

    let controller =
        BottomSheetContainerViewController(rootTabBarController: tabBarController,
                                           viewControllers: tabControllers + rightDrawerItems)
    return controller
  }()

  lazy var tabBarController: UITabBarController = {
    let tabBarController = UITabBarController()

    scheduleNavigator.navigateToStart()

    let attributes = [
      NSAttributedString.Key.foregroundColor: UIColor(red: 60 / 255, green: 64 / 255, blue: 67 / 255, alpha: 1)
    ]
    let selectedAttributes = [
      NSAttributedString.Key.foregroundColor: LayoutConstants.tabBarTintColor
    ]
    UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .normal)
    UITabBarItem.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
    tabBarController.viewControllers?.forEach { controller in
      let font = UIFont.systemFont(ofSize: LayoutConstants.tabBarTextSize,
                                   weight: UIFont.Weight.medium)
      let attributes = [ NSAttributedString.Key.font: font ]

      controller.tabBarItem.setTitleTextAttributes(attributes, for: .normal)
      controller.tabBarItem.titlePositionAdjustment =
          UIOffset(horizontal: 0,
                   vertical: LayoutConstants.tabBarVerticalOffset)
    }
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
    let navigator = DefaultOnboardingNavigator(serviceLocator: serviceLocator,
                                               pageViewController: pageViewController)
    navigator.onOnboardingCompleted {
      self.activateMainInterface()
    }
    navigator.navigateToStart()

    return pageViewController
  }()

  // MARK: - Manage UI flow and switching from onboarding to the main flow

  func activateMainInterface() {
    window?.rootViewController = sideNavigationController

    // Release the onboarding flow so it can be deallocated.
    onboardingPageViewController?.view.removeFromSuperview()
    onboardingPageViewController?.dismiss(animated: false, completion: nil)
    onboardingPageViewController = nil

    window?.makeKeyAndVisible()
  }

  var window: UIWindow?

  func configureMainInterface(in window: UIWindow?) {
    self.window = window
    registerForModelUpdates()
    if shouldDisplayOnboarding() {
      window?.rootViewController = onboardingPageViewController
    } else {
      window?.rootViewController = sideNavigationController
    }
  }

  private func registerForModelUpdates() {
    serviceLocator.sessionsDataSource.update()
    registerImFeelingLuckyShortcut()
  }

}

extension Application {
  fileprivate func shouldDisplayOnboarding() -> Bool {
    let userState = serviceLocator.userState
    return userState.shouldDisplayOnboarding
  }
}

public class RootNavigator {

  let application: Application
  init(_ application: Application) {
    self.application = application
  }

  public func navigateToSchedule(day: Int? = nil) {
    application.tabBarController.selectedViewController = application.scheduleNavigationController
    application.scheduleNavigationController.popToRootViewController(animated: true)
    if let day = day {
      application.scheduleNavigator.navigateToDay(day)
    }
  }

  public func navigate(to session: Session) {
    navigateToSchedule()
    application.scheduleNavigator.navigate(to: session, popToRoot: false)
  }

  public func navigateInSearchResults(to session: Session) {
    switch application.tabBarController.selectedViewController {
    case application.homeNavigationController:
      application.homeViewController.searchViewController.showSession(session)
    case application.scheduleNavigationController:
      application.scheduleNavigator.navigate(to: session, popToRoot: false)

    case _:
      break
    }
  }

  public func navigateToMap(roomId: String?) {
    let shouldPopToRoot =
        application.tabBarController.selectedViewController == application.mapNavigationController
    application.tabBarController.selectedViewController = application.mapNavigationController
    if shouldPopToRoot {
      application.mapNavigationController.popToRootViewController(animated: true)
    }
    application.mapViewController.select(roomId: roomId)
  }

  public func navigateToInfoItem(_ infoDetail: InfoDetail) {
    navigateToInfo()
    application.infoViewController.showInfo(infoDetail, animated: true)
  }

  public func navigateToInfo() {
    if let navigationController = application.tabBarController.selectedViewController
      as? UINavigationController {
      navigationController.pushViewController(application.infoViewController, animated: true)
    }
  }

  public func navigateToAgendaItem(_ agendaItem: AgendaItem) {
    if let navigationController = application.tabBarController.selectedViewController
      as? UINavigationController {
      navigationController.pushViewController(application.agendaViewController, animated: true)
      application.agendaViewController.showAgendaItem(agendaItem)
    }
  }
}
