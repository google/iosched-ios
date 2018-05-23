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
import MaterialComponents
import UIKit
import SafariServices

public protocol ScheduleNavigator {
  func navigateToURL(_ url: URL)
  func navigateToStart()
  func navigateToDay(_ day: Int)
  func navigateToSchedule()
  func navigate(to session: Session, popToRoot: Bool)
  func navigateToSessionDetails(sessionID: String, popToRoot: Bool)
  func navigateToSpeakerDetails(speaker: Speaker, popToRoot: Bool)
  func navigateToFeedback(sessionID: String, title: String)
  func detailsViewController(for session: Session) -> UIViewController
  func speakerDetailsViewController(for speaker: Speaker) -> UIViewController
  func shareSessionDetails(items: [Any], sourceView: UIView?, sourceRect: CGRect?)
  func navigateToFilter(viewModel: ScheduleFilterViewModel, callback: @escaping () -> Void)
  func navigateToAccount()
  func navigateToMap(roomId: String?)
  func showCancellationDialog(title: String, message: String, _ completion: @escaping (_ confirmCancellation: Bool) -> Void)
  func showReservationClashDialog(swapHandler: @escaping () -> Void)
  func showMultiClashDialog()
}

public final class DefaultScheduleNavigator: ScheduleNavigator {
  private enum DialogConstants {
    static let confirmCancellationOK = NSLocalizedString("Yes", comment: "Button title to confirm a cancellation action.")
    static let confirmCancellationCancel = NSLocalizedString("No", comment: "Button title to decline a cancellation action. Please avoid using phrases containing 'cancel' as they may be ambiguous.")

    static let swapButtonTitle = NSLocalizedString(
      "Swap reservation",
      comment: "Button text for swapping or exchanging an existing reservation for a new one"
    )
    static let conflictMessageDismissText = NSLocalizedString("OK", comment: "Dismiss dialog button text")

    static let conflictTitle = NSLocalizedString("Time conflict", comment: "Conflict dialog title")
    static let conflictMessage = NSLocalizedString("You already have a reservation/waitlist request for this time. Only one reservation per time block is allowed.", comment: "Conflicting reservations message. The second sentence should explain that reservations for sessions/events that occur at the same time are not allowed.")

    static let multiClashTitle = NSLocalizedString("Time conflict", comment: "Conflict dialog title")
    static let multiClashMessage = NSLocalizedString("You have multiple conflicting reservations. Please remove all of your conflicting reservations to reserve this event.", comment: "Conflicting reservations message. The second sentence provides instructions on how to resolve the conflicting reservations.")
  }

  private let serviceLocator: ServiceLocator
  private let rootNavigator: RootNavigator
  private let navigationController: UINavigationController
  private lazy var clashDetector =
      ReservationClashDetector(sessions: serviceLocator.sessionsDataSource,
                               reservations: serviceLocator.reservationDataSource)

  init(serviceLocator: ServiceLocator,
       rootNavigator: RootNavigator,
       navigationController: UINavigationController) {
    self.serviceLocator = serviceLocator
    self.rootNavigator = rootNavigator
    self.navigationController = navigationController
  }

  public func navigateToStart() {
    navigateToSchedule()
  }

  public func navigateToURL(_ url: URL) {
    navigationController.present(SFSafariViewController(url: url), animated: true, completion: nil)
  }

  lazy var scheduleViewController: ScheduleViewController = {
    let viewModel = DefaultSessionListViewModel(
      sessionsDataSource: serviceLocator.sessionsDataSource,
      bookmarkDataSource: serviceLocator.bookmarkDataSource,
      reservationDataSource: serviceLocator.reservationDataSource,
      navigator: self
    )
    let displayableViewModel = ScheduleDisplayableViewModel(wrappedModel: viewModel)
    let searchController = SearchCollectionViewController(rootNavigator: rootNavigator,
                                                          serviceLocator: serviceLocator)
    searchController.scheduleNavigator = self
    return ScheduleViewController(viewModel: displayableViewModel,
                                  searchViewController: searchController)
  }()

  public func navigateToDay(_ day: Int) {
    scheduleViewController.loadViewIfNeeded()
    scheduleViewController.selectDay(day: day)
  }

  public func navigateToSchedule() {
    navigationController.pushViewController(scheduleViewController, animated: true)
  }

  public func navigateToSessionDetails(sessionID: String, popToRoot: Bool = false) {
    guard let session = serviceLocator.sessionsDataSource[sessionID] else {
      print("Session not found in data source: \(sessionID)")
      return
    }
    navigate(to: session)
  }

  public func navigate(to session: Session, popToRoot: Bool = false) {
    let viewModel = SessionDetailsViewModel(
      session: session,
      bookmarkDataSource: serviceLocator.bookmarkDataSource,
      reservationDataSource: serviceLocator.reservationDataSource,
      clashDetector: clashDetector,
      userState: serviceLocator.userState,
      navigator: self
    )
    let viewController = SessionDetailsViewController(viewModel: viewModel)

    // needed for I'm feeling lucky and deep linking
    if popToRoot {
      navigationController.popToRootViewController(animated: false)
    }
    navigationController.pushViewController(viewController, animated: true)
  }

  public func navigateToSpeakerDetails(speaker: Speaker, popToRoot: Bool = false) {
    let viewModel = SpeakerDetailsViewModel(
      sessionsDataSource: serviceLocator.sessionsDataSource,
      bookmarkDataSource: serviceLocator.bookmarkDataSource,
      reservationDataSource: serviceLocator.reservationDataSource,
      navigator: self,
      speaker: speaker
    )
    let viewController = SpeakerDetailsViewController(viewModel: viewModel)

    // needed for I'm feeling lucky and deep linking
    if popToRoot {
      navigationController.popToRootViewController(animated: false)
    }
    navigationController.pushViewController(viewController, animated: true)
  }

  public func navigateToFeedback(sessionID: String, title: String) {
    let feedbackController = SessionFeedbackViewController(sessionID: sessionID,
                                                           title: title,
                                                           userState: serviceLocator.userState)
    navigationController.present(feedbackController, animated: true, completion: nil)
  }

  public func detailsViewController(for session: Session) -> UIViewController {
    let viewModel = SessionDetailsViewModel(
      session: session,
      bookmarkDataSource: serviceLocator.bookmarkDataSource,
      reservationDataSource: serviceLocator.reservationDataSource,
      clashDetector: clashDetector,
      userState: serviceLocator.userState,
      navigator: self
    )
    let viewController = SessionDetailsViewController(viewModel: viewModel)
    return viewController
  }

  public func speakerDetailsViewController(for speaker: Speaker) -> UIViewController {
    let viewModel = SpeakerDetailsViewModel(
      sessionsDataSource: serviceLocator.sessionsDataSource,
      bookmarkDataSource: serviceLocator.bookmarkDataSource,
      reservationDataSource: serviceLocator.reservationDataSource,
      navigator: self,
      speaker: speaker
    )
    let viewController = SpeakerDetailsViewController(viewModel: viewModel)
    return viewController
  }

  public func shareSessionDetails(items: [Any], sourceView: UIView? = nil, sourceRect: CGRect? = nil) {
    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let view = sourceView, let rect = sourceRect {
      activityViewController.popoverPresentationController?.sourceView = view
      activityViewController.popoverPresentationController?.sourceRect = rect
    } else {
      activityViewController.popoverPresentationController?.sourceView = navigationController.view
    }

    navigationController.present(activityViewController, animated: true, completion: {})
  }

  public func navigateToFilter(viewModel: ScheduleFilterViewModel, callback: @escaping () -> Void) {
    let filterViewController = ScheduleFilterViewController(viewModel: viewModel, doneCallback: {
      callback()
      self.navigationController.dismiss(animated: true, completion: nil)
    })
    navigationController.present(filterViewController, animated: true, completion: nil)
  }

  public func navigateToAccount() {
    let viewModel = UserAccountInfoViewModel(userState: serviceLocator.userState)
    let settingsViewModel = SettingsViewModel(userState: self.serviceLocator.userState)
    let viewController = UserAccountInfoViewController(viewModel: viewModel, settingsViewModel: settingsViewModel)
    navigationController.present(viewController, animated: true, completion: nil)
  }

  public func navigateToMap(roomId: String?) {
    rootNavigator.navigateToMap(roomId: roomId)
  }

  public func showCancellationDialog(title: String, message: String, _ completion: @escaping (_ confirmCancellation: Bool) -> Void) {
    let alertController = MDCAlertController(title: title,
                                             message: message)
    styleAlertController(alertController)
    let actionOK = MDCAlertAction(title: DialogConstants.confirmCancellationOK) { (_) in
      completion(true)
    }

    let actionCancel = MDCAlertAction(title: DialogConstants.confirmCancellationCancel) { (_) in
      completion(false)
    }

    alertController.addAction(actionOK)
    alertController.addAction(actionCancel)

    navigationController.present(alertController, animated: true, completion: nil)
  }

  public func showReservationClashDialog(swapHandler: @escaping () -> Void) {
    let alertController = MDCAlertController(title: DialogConstants.conflictTitle,
                                             message: DialogConstants.conflictMessage)
    styleAlertController(alertController)
    let actionOK = MDCAlertAction(title: DialogConstants.conflictMessageDismissText) { (_) in }
    let swapAction = MDCAlertAction(title: DialogConstants.swapButtonTitle) { _ in
      swapHandler()
    }

    alertController.addAction(actionOK)
    alertController.addAction(swapAction)
    navigationController.present(alertController, animated: true, completion: nil)
  }

  public func showMultiClashDialog() {
    let alertController = MDCAlertController(title: DialogConstants.multiClashTitle,
                                             message: DialogConstants.multiClashMessage)
    styleAlertController(alertController)
    let actionOK = MDCAlertAction(title: DialogConstants.conflictMessageDismissText) { (_) in }

    alertController.addAction(actionOK)
    navigationController.present(alertController, animated: true, completion: nil)
  }

  private func styleAlertController(_ controller: MDCAlertController) {
    controller.cornerRadius = 8
    controller.titleFont = ProductSans.regular.style(.callout)
    controller.titleColor = UIColor(red: 32 / 255, green: 33 / 255, blue: 36 / 255, alpha: 1)
    controller.messageFont = UIFont.preferredFont(forTextStyle: .footnote)
    controller.messageColor = UIColor(red: 65 / 255, green: 69 / 255, blue: 73 / 255, alpha: 1)
    controller.buttonFont = ProductSans.regular.style(.body)
    controller.mdc_adjustsFontForContentSizeCategory = true
    controller.buttonTitleColor =
        UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
  }

}
