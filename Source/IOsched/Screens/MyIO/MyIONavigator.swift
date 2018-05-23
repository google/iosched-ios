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
import SafariServices

final class DefaultMyIONavigator: ScheduleNavigator {

  private enum DialogConstants {
    static let confirmCancellationOK = NSLocalizedString("OK", comment: "OK button")
    static let confirmCancellationCancel = NSLocalizedString("Cancel", comment: "Cancel button")

    static let conflictTitle = NSLocalizedString("Time conflict", comment: "Conflict title")
    static let conflictMessage = NSLocalizedString("You already have a reservation/waitlist request for this time. Only one reservation per time block is allowed; please cancel your previous request if you’d like to proceed.", comment: "Conflict message")
  }

  private let serviceLocator: ServiceLocator
  private let rootNavigator: RootNavigator
  private let navigationController: UINavigationController

  init(serviceLocator: ServiceLocator, rootNavigator: RootNavigator, navigationController: UINavigationController) {
    self.serviceLocator = serviceLocator
    self.rootNavigator = rootNavigator
    self.navigationController = navigationController
  }

  func navigateToScheduleTab() {
    rootNavigator.navigateToSchedule()
  }

  func navigateToURL(_ url: URL) {
    navigationController.present(SFSafariViewController(url: url), animated: true, completion: nil)
  }

  func navigateToStart() {
    navigateToSchedule()
  }

  func navigateToSpeakerDetails(speaker: Speaker, popToRoot: Bool = false) {
    let viewModel = SpeakerDetailsViewModel(conferenceDataSource: serviceLocator.conferenceDataSource,
                                            bookmarkStore: serviceLocator.bookmarkStore,
                                            reservationStore: serviceLocator.reservationStore,
                                            navigator: self,
                                            speaker: speaker)
    let viewController = SpeakerDetailsViewController(viewModel: viewModel)
    navigationController.pushViewController(viewController, animated: true)
  }

  lazy var scheduleViewController: ScheduleViewController = {
    let viewModel = MyIOViewModel(conferenceDataSource: self.serviceLocator.conferenceDataSource,
                                  bookmarkStore: self.serviceLocator.bookmarkStore,
                                  reservationStore: self.serviceLocator.reservationStore,
                                  userState: self.serviceLocator.userState,
                                  rootNavigator: self.rootNavigator,
                                  navigator: self)
    let composedViewModel = MyIOComposedViewModel(wrappedModel: viewModel, navigator: self)
    return MyIOViewController(viewModel: composedViewModel, myIOViewModel: composedViewModel)
  }()

  func navigateToDay(day: Int) {
    scheduleViewController.selectedTabIndex = day
  }

  func navigateToSchedule() {
    navigationController.pushViewController(scheduleViewController, animated: true)
  }

  func navigateToSessionDetails(sessionId: String, popToRoot: Bool = false) {
    let viewModel = SessionDetailsViewModel(conferenceDataSource: serviceLocator.conferenceDataSource,
                                            bookmarkStore: serviceLocator.bookmarkStore,
                                            reservationStore: serviceLocator.reservationStore,
                                            userState: serviceLocator.userState,
                                            navigator: self,
                                            sessionId: sessionId)
    let viewController = MyIOSessionDetailsViewController(viewModel: viewModel)
    navigationController.pushViewController(viewController, animated: true)
  }

  func navigateToFeedback(sessionId: String, title: String) {
    let feedbackController = SessionFeedbackViewController(sessionID: sessionId,
                                                           title: title,
                                                           userState: serviceLocator.userState)
    navigationController.present(feedbackController, animated: true, completion: nil)
  }

  func detailsViewController(for sessionId: String) -> UIViewController {
    let viewModel = SessionDetailsViewModel(conferenceDataSource: serviceLocator.conferenceDataSource,
                                            bookmarkStore: serviceLocator.bookmarkStore,
                                            reservationStore: serviceLocator.reservationStore,
                                            userState: serviceLocator.userState,
                                            navigator: self,
                                            sessionId: sessionId)
    let viewController = MyIOSessionDetailsViewController(viewModel: viewModel)
    return viewController
  }

  func speakerDetailsViewController(for speaker: Speaker) -> UIViewController {
    let viewModel = SpeakerDetailsViewModel(conferenceDataSource: serviceLocator.conferenceDataSource,
                                            bookmarkStore: serviceLocator.bookmarkStore,
                                            reservationStore: serviceLocator.reservationStore,
                                            navigator: self,
                                            speaker: speaker)
    let viewControler = SpeakerDetailsViewController(viewModel: viewModel)
    return viewControler
  }

  func shareSessionDetails(items: [Any], sourceView: UIView? = nil, sourceRect: CGRect? = nil) {
    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

    navigationController.present(activityViewController, animated: true, completion: {})
  }

  func navigateToFilter(viewModel: ScheduleFilterViewModel, callback: @escaping ScheduleFilterCompletedCallback) {
    // do nothing
  }

  func navigateToAccount() {
    let viewModel = UserAccountInfoViewModel(userState: serviceLocator.userState, navigator: self)
    let settingsViewModel = SettingsViewModel(userState: self.serviceLocator.userState)
    let viewController = UserAccountInfoViewController(viewModel: viewModel, settingsViewModel:settingsViewModel)
    navigationController.present(viewController, animated: true, completion: nil)
  }

  func showCancellationDialog(title: String, message: String, _ completion: @escaping (_ confirmCancellation: Bool) -> Void) {
    let alertController = MDCAlertController(title: title,
                                             message: message)
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

  func showReservationClashDialog() {
    let alertController = MDCAlertController(title: DialogConstants.conflictTitle, message: DialogConstants.conflictMessage)

    let actionOK = MDCAlertAction(title: DialogConstants.confirmCancellationOK) { (_) in
    }

    alertController.addAction(actionOK)

    navigationController.present(alertController, animated: true, completion: nil)
  }

  func navigateToMap(roomId: String?) {
    rootNavigator.navigateToMap(roomId: roomId)
  }

  func showBookmarkToast(viewModel: ScheduleViewModel?, isBookmarked: Bool) {
  }
}
