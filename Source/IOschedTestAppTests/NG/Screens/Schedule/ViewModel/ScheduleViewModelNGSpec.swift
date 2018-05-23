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
import Quick
import Nimble

@testable import Domain
@testable import Platform
@testable import IOschedTestApp

// TODO(morganchen): This test file was broken when updating dependencies from 2017 to 2018.

/*

class ScheduleViewModelNGSpec: QuickSpec {

  override func spec() {
    describe("ScheduleViewModelNG") {
      var conferenceUsecase: ConferenceDataSource!
      var viewModel: DefaultScheduleViewModel!

      beforeEach {
        let datasource = BootstrappedScheduleDatasource()
        let sessionsRepository = DefaultSessionsRepository(datasource: datasource)
        let blocksRepository = DefaultBlocksRepository(datasource: datasource)
        let roomsRepository = DefaultRoomsRepository(datasource: datasource)
        let tagsRepository = DefaultTagsRepository(datasource: datasource)
        let speakersRepository = DefaultSpeakersRepository(datasource: datasource)
        let mapRepository = DefaultMapRepository(datasource: datasource)
        conferenceUsecase = DefaultConferenceDataSource(sessionsRepository: sessionsRepository,
                                                     blocksRepository: blocksRepository,
                                                     roomsRepository: roomsRepository,
                                                     tagsRepository: tagsRepository,
                                                     speakersRepository: speakersRepository,
                                                     mapRepository: mapRepository)

        viewModel = DefaultScheduleViewModel(
          conferenceUsecase: conferenceUsecase,
          bookmarkUseCase: EmptyBookmarkUseCase(),
          reservationUseCase: EmptyWritableReservationStore(),
          userState: EmptyUserStateUseCase(),
          rootNavigator: RootNavigator(Application.sharedInstance),
          navigator: Application.sharedInstance.scheduleNavigator
        )
      }

      it("Number of days should be non-zero") {
        let days = viewModel.conferenceDays
        expect(days?.count) > 0
      }

      context("Timezone awareness") {
        it("The view model listens for timezone changes and updates its presentation accordingly") {
          
          // 1) set timezone to Europe/Berlin, and set preferences to use local timezone
          let savedTimeZone = NSTimeZone.default
          NSTimeZone.default = TimeZone(identifier: "Europe/Berlin")!
          UserDefaults.standard.setEventsInPacificTime(false)

          dump(days: viewModel.conferenceDays!)

          // 2) check that it has the correct structure (i.e. correct number of days and events in each day
          let localTZDays = viewModel.conferenceDays

          expect(localTZDays?.count) == 5
          
          let localTZDay1 = localTZDays?[0]
          expect(localTZDay1?.dayString) == "16. May"
          expect(localTZDay1?.slots.count) == 2
          
          let localTZDay2 = localTZDays?[1]
          expect(localTZDay2?.dayString) == "17. May"
          expect(localTZDay2?.slots.count) == 4
          expect(localTZDay2?.slots[0].events.count) == 2
          expect(localTZDay2?.slots[1].events.count) == 3
          expect(localTZDay2?.slots[2].events.count) == 5
          expect(localTZDay2?.slots[3].events.count) == 3
          
          let localTZDay3 = localTZDays?[2]
          expect(localTZDay3?.dayString) == "18. May"
          expect(localTZDay3?.slots.count) == 13
          expect(localTZDay3?.slots[0].events.count) == 3
          expect(localTZDay3?.slots[1].events.count) == 3
          expect(localTZDay3?.slots[11].events.count) == 4
          expect(localTZDay3?.slots[12].events.count) == 6
          
          let localTZDay4 = localTZDays?[3]
          expect(localTZDay4?.dayString) == "19. May"
          expect(localTZDay4?.slots.count) == 14
          expect(localTZDay4?.slots[0].events.count) == 5
          expect(localTZDay4?.slots[1].events.count) == 4
          expect(localTZDay4?.slots[12].events.count) == 5
          expect(localTZDay4?.slots[13].events.count) == 4
          
          let localTZDay5 = localTZDays?[4]
          expect(localTZDay5?.dayString) == "20. May"
          expect(localTZDay5?.slots.count) == 1
          expect(localTZDay5?.slots[0].events.count) == 4
          
          // 4) switch to showing PDT times (but stay in Europe/Berlin TZ!)
          UserDefaults.standard.setEventsInPacificTime(true)
          let pacificTZDays = viewModel.conferenceDays
          dump(days: viewModel.conferenceDays!)
          
          // 5) check that viewmodel has correct structure (correct number of days and events in each day)
          expect(pacificTZDays?.count) == 4
          
          let pacificTZDay1 = pacificTZDays?[0]
          expect(pacificTZDay1?.dayString) == "16. May"
          expect(pacificTZDay1?.slots.count) == 2
          
          let pacificTZDay2 = pacificTZDays?[1]
          expect(pacificTZDay2?.dayString) == "17. May"
          expect(pacificTZDay2?.slots.count) == 8
          expect(pacificTZDay2?.slots[0].events.count) == 2
          expect(pacificTZDay2?.slots[1].events.count) == 3
          expect(pacificTZDay2?.slots[2].events.count) == 5
          expect(pacificTZDay2?.slots[3].events.count) == 3
          
          let pacificTZDay3 = pacificTZDays?[2]
          expect(pacificTZDay3?.dayString) == "18. May"
          expect(pacificTZDay3?.slots.count) == 14
          expect(pacificTZDay3?.slots[0].events.count) == 1
          expect(pacificTZDay3?.slots[1].events.count) == 1
          expect(pacificTZDay3?.slots[11].events.count) == 5
          expect(pacificTZDay3?.slots[12].events.count) == 5
          
          let pacificTZDay4 = pacificTZDays?[3]
          expect(pacificTZDay4?.dayString) == "19. May"
          expect(pacificTZDay4?.slots.count) == 10
          expect(pacificTZDay4?.slots[0].events.count) == 1
          expect(pacificTZDay4?.slots[1].events.count) == 1
          expect(pacificTZDay4?.slots[8].events.count) == 4
          expect(pacificTZDay4?.slots[9].events.count) == 4
          
          // 6) switch back to non-PDT display
          UserDefaults.standard.setEventsInPacificTime(false)
          
          // 7) again, check correct structure
          let localAgainTZDays = viewModel.conferenceDays
          
          expect(localAgainTZDays?.count) == 5
          
          let localAgainTZDay1 = localAgainTZDays?[0]
          expect(localAgainTZDay1?.dayString) == "16. May"
          expect(localAgainTZDay1?.slots.count) == 2
          
          let localAgainTZDay2 = localAgainTZDays?[1]
          expect(localAgainTZDay2?.dayString) == "17. May"
          expect(localAgainTZDay2?.slots.count) == 4
          expect(localAgainTZDay2?.slots[0].events.count) == 2
          expect(localAgainTZDay2?.slots[1].events.count) == 3
          expect(localAgainTZDay2?.slots[2].events.count) == 5
          expect(localAgainTZDay2?.slots[3].events.count) == 3
          
          let localAgainTZDay3 = localAgainTZDays?[2]
          expect(localAgainTZDay3?.dayString) == "18. May"
          expect(localAgainTZDay3?.slots.count) == 13
          expect(localAgainTZDay3?.slots[0].events.count) == 3
          expect(localAgainTZDay3?.slots[1].events.count) == 3
          expect(localAgainTZDay3?.slots[11].events.count) == 4
          expect(localAgainTZDay3?.slots[12].events.count) == 6
          
          let localAgainTZDay4 = localAgainTZDays?[3]
          expect(localAgainTZDay4?.dayString) == "19. May"
          expect(localAgainTZDay4?.slots.count) == 14
          expect(localAgainTZDay4?.slots[0].events.count) == 5
          expect(localAgainTZDay4?.slots[1].events.count) == 4
          expect(localAgainTZDay4?.slots[12].events.count) == 5
          expect(localAgainTZDay4?.slots[13].events.count) == 4
          
          let localAgainTZDay5 = localAgainTZDays?[4]
          expect(localAgainTZDay5?.dayString) == "20. May"
          expect(localAgainTZDay5?.slots.count) == 1
          expect(localTZDay5?.slots[0].events.count) == 4
        }
        
        it("The view model listens for timezone changes, even when starting in the pacific timezone") {
          // 1) set timezone to Pacific, and set preferences to use local timezone
          let savedTimeZone = NSTimeZone.default
          NSTimeZone.default = TimeZone(identifier: "America/Los_Angeles")!
          UserDefaults.standard.setEventsInPacificTime(false)

          // 2) check that viewmodel has the correct structure (correct number of days and events in each day)
          let pacificTZDays = viewModel.conferenceDays
          expect(pacificTZDays?.count) == 4
          
          let pacificTZDay1 = pacificTZDays?[0]
          expect(pacificTZDay1?.dayString) == "16. May"
          expect(pacificTZDay1?.slots.count) == 2
          
          let pacificTZDay2 = pacificTZDays?[1]
          expect(pacificTZDay2?.dayString) == "17. May"
          expect(pacificTZDay2?.slots.count) == 8
          expect(pacificTZDay2?.slots[0].events.count) == 2
          expect(pacificTZDay2?.slots[1].events.count) == 3
          expect(pacificTZDay2?.slots[2].events.count) == 5
          expect(pacificTZDay2?.slots[3].events.count) == 3
          
          let pacificTZDay3 = pacificTZDays?[2]
          expect(pacificTZDay3?.dayString) == "18. May"
          expect(pacificTZDay3?.slots.count) == 14
          expect(pacificTZDay3?.slots[0].events.count) == 1
          expect(pacificTZDay3?.slots[1].events.count) == 1
          expect(pacificTZDay3?.slots[11].events.count) == 5
          expect(pacificTZDay3?.slots[12].events.count) == 5
          
          let pacificTZDay4 = pacificTZDays?[3]
          expect(pacificTZDay4?.dayString) == "19. May"
          expect(pacificTZDay4?.slots.count) == 10
          expect(pacificTZDay4?.slots[0].events.count) == 1
          expect(pacificTZDay4?.slots[1].events.count) == 1
          expect(pacificTZDay4?.slots[8].events.count) == 4
          expect(pacificTZDay4?.slots[9].events.count) == 4
          
          // 4) switch to showing PDT times
          UserDefaults.standard.setEventsInPacificTime(true)
          let pacificAgainTZDays = viewModel.conferenceDays
          
          // 5) check that viewmodel has correct structure (correct number of days and events in each day)
          expect(pacificAgainTZDays?.count) == 4
          
          let pacificAgainTZDay1 = pacificAgainTZDays?[0]
          expect(pacificAgainTZDay1?.dayString) == "16. May"
          expect(pacificAgainTZDay1?.slots.count) == 2
          
          let pacificAgainTZDay2 = pacificAgainTZDays?[1]
          expect(pacificAgainTZDay2?.dayString) == "17. May"
          expect(pacificAgainTZDay2?.slots.count) == 8
          expect(pacificAgainTZDay2?.slots[0].events.count) == 2
          expect(pacificAgainTZDay2?.slots[1].events.count) == 3
          expect(pacificAgainTZDay2?.slots[2].events.count) == 5
          expect(pacificAgainTZDay2?.slots[3].events.count) == 3
          
          let pacificAgainTZDay3 = pacificAgainTZDays?[2]
          expect(pacificAgainTZDay3?.dayString) == "18. May"
          expect(pacificAgainTZDay3?.slots.count) == 14
          expect(pacificAgainTZDay3?.slots[0].events.count) == 1
          expect(pacificAgainTZDay3?.slots[1].events.count) == 1
          expect(pacificAgainTZDay3?.slots[11].events.count) == 5
          expect(pacificAgainTZDay3?.slots[12].events.count) == 5
          
          let pacificAgainTZDay4 = pacificAgainTZDays?[3]
          expect(pacificAgainTZDay4?.dayString) == "19. May"
          expect(pacificAgainTZDay4?.slots.count) == 10
          expect(pacificAgainTZDay4?.slots[0].events.count) == 1
          expect(pacificAgainTZDay4?.slots[1].events.count) == 1
          expect(pacificAgainTZDay4?.slots[8].events.count) == 4
          expect(pacificAgainTZDay4?.slots[9].events.count) == 4
        }
        
        it("The view model listens for timezone changes as the user travels through various timezones on their way to I/O") {
          
        }
      }
      
      func dump(days: [ConferenceDayViewModel]) {
        days.forEach { dayViewModel in
          print("Day: \(dayViewModel.dayString)")
          dayViewModel.slots.forEach { conferenceTimeSlotViewModel in
            print("  \(conferenceTimeSlotViewModel.timeSlotString)")
            
            conferenceTimeSlotViewModel.events.forEach { conferenceEventViewModel in
              // print("    \(conferenceEventViewModel.startTimeString): \(conferenceEventViewModel.title)")
            }
          }
        }
      }
      
    }
  }
}

*/
