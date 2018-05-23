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

import UIKit

protocol DaySelectable {
  var selectedDay: Int { get set }
}

class ScheduleComposedViewModel: ComposedViewModel {

  var navigator: ScheduleNavigator

  var wrappedModel: ScheduleViewModel

  var selectedDay = 0 {
    didSet {
      for case var viewModel as DaySelectable in viewModels {
        viewModel.selectedDay = selectedDay
      }
    }
  }

  var conferenceDays: [ConferenceDayViewModel] {
    return wrappedModel.conferenceDays
  }

//  func detailsViewController(for session: ConferenceEventViewModel) -> UIViewController {
//    return wrappedModel.detailsViewController(for: session)
//  }

  func filterSelected() {
    wrappedModel.didSelectFilter()
  }

  func invalidateHeights() {
    for viewModel in viewModels {
      if let scheduleViewModel = viewModel as? ScheduleComposableViewModel {
        scheduleViewModel.invalidateHeights()
      }
    }
  }

  init(wrappedModel: ScheduleViewModel, navigator: ScheduleNavigator) {
    self.wrappedModel = wrappedModel
    self.navigator = navigator
    super.init()
  }

  override func initializeViewModels() -> [ComposableViewModel] {
    return [ScheduleComposableViewModel(wrappedModel: wrappedModel)]
  }

  func accountSelected() {
    if let viewModel = wrappedModel as? DefaultScheduleViewModel {
      viewModel.accountSelected()
    }
  }

  // MARK: - View updates
  var viewUpdateCallback: ((_ indexPath: IndexPath?) -> Void)?
  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void) {
    wrappedModel.onUpdate { indexPath in
      viewUpdateCallback(indexPath)
    }
  }

  func updateModel() {
    wrappedModel.updateModel()
  }

}
