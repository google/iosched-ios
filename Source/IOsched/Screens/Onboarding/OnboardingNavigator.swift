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

import Foundation
import UIKit
import Domain
import MaterialComponents
import GoogleSignIn

typealias OnboardingCompletedCallback = () -> Void

protocol OnboardingNavigator: NSObjectProtocol {
  func navigateToStart()
  func navigateToWelcome()
  func navigateToSchedule()
  func navigateToCountdown()
  func navigateToMainNavigation()
  func showLoginSuccessfulMessage(user: GIDGoogleUser)
  func showLoginFailedMessage()
  func onOnboardingCompleted(_ callback: @escaping OnboardingCompletedCallback)
}

final class DefaultOnboardingNavigator: NSObject, OnboardingNavigator, SignInNavigatable {
  private let pageViewController: UIPageViewController
  private let serviceLocator: ServiceLocator

  private lazy var viewModel: OnboardingViewModel = {
    OnboardingViewModel(serviceLocator: serviceLocator, navigator: self)
  }()

  private lazy var welcomeController = OnboardingWelcomeViewController(viewModel: viewModel)
  private lazy var scheduleController = OnboardingSessionsViewController(viewModel: viewModel)
  private lazy var countdownController = OnboardingCountdownViewController(viewModel: viewModel)

  init(serviceLocator: ServiceLocator, pageViewController: UIPageViewController) {
    self.serviceLocator = serviceLocator
    self.pageViewController = pageViewController
    super.init()
    self.pageViewController.dataSource = self
  }

  func navigateToStart() {
    navigateToWelcome()

    // Enable analytics by default. This line of code assumes
    // this method will only execute on new installs, and must
    // execute before any important stuff we'd want to capture
    // in analytics.
    serviceLocator.userState.setAnalyticsEnabled(true)
  }

  func navigateToWelcome() {
    pageViewController.setViewControllers([welcomeController],
                                          direction: .forward,
                                          animated: true,
                                          completion: nil)
  }

  func navigateToSchedule() {
    pageViewController.setViewControllers([scheduleController],
                                          direction: .forward,
                                          animated: true,
                                          completion: nil)
  }

  func navigateToCountdown() {
    pageViewController.setViewControllers([countdownController],
                                          direction: .forward,
                                          animated: true,
                                          completion: nil)
  }

  func navigateToMainNavigation() {
    onboardingCompletedCallback?()
  }

  var onboardingCompletedCallback: OnboardingCompletedCallback?
  func onOnboardingCompleted(_ callback: @escaping OnboardingCompletedCallback) {
    onboardingCompletedCallback = callback
  }

}

extension DefaultOnboardingNavigator: UIPageViewControllerDataSource {

  func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    guard let controller = pageViewController.viewControllers?.first else { return 0 }
    switch controller {
    case controller as OnboardingWelcomeViewController:
      return 0
    case controller as OnboardingSessionsViewController:
      return 1
    case controller as OnboardingCountdownViewController:
      return 2
    case _:
      fatalError("Unsupported type in Onboarding Navigator")
    }
  }

  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return 3
  }

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter controller: UIViewController) -> UIViewController? {
    switch controller {
    case welcomeController:
      return scheduleController
    case scheduleController:
      return countdownController
    case countdownController:
      return nil
    case _:
      return nil
    }
  }

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore controller: UIViewController) -> UIViewController? {
    switch controller {
    case welcomeController:
      return nil
    case scheduleController:
      return welcomeController
    case countdownController:
      return scheduleController
    case _:
      return nil
    }
  }

  func completeOnboardingFlow() {
    welcomeController.view.removeFromSuperview()
    scheduleController.view.removeFromSuperview()
    countdownController.view.removeFromSuperview()
  }

}
