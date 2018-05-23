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
import Platform
import MaterialComponents

class MyIOComposedViewModel: ScheduleComposedViewModel {

  override func initializeViewModels() -> [ComposableViewModel] {
    return [
      ScheduleComposableViewModel(wrappedModel: wrappedModel)
    ]
  }

  func isEmpty(forDayWithIndex index: Int) -> Bool {
    guard let viewModel = wrappedModel as? MyIOViewModel else { return true }
    return viewModel.slots(forDayWithIndex: index)?.count == 0
  }

  func myIOAccountSelected() {
    if let viewModel = wrappedModel as? MyIOViewModel {
      viewModel.myIOAccountSelected()
    }
  }

  override func populateSupplementaryView(_ view: UICollectionReusableView, forItemAt indexPath: IndexPath) {
    if let sectionHeader = view as? MDCCollectionViewTextCell,
       let slots = wrappedModel.slots(forDayWithIndex: selectedDay),
       slots.count > 0 {
        sectionHeader.shouldHideSeparator = true
        let slot = slots[indexPath.section - (numberOfSections()-slots.count)]
        sectionHeader.textLabel?.text = slot.timeSlotString
    } else {
      super.populateSupplementaryView(view, forItemAt: indexPath)
    }
  }
}
