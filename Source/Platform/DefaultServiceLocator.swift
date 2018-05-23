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

public final class DefaultServiceLocator: ServiceLocator {

  // MARK: - Singleton
  public static let sharedInstance = DefaultServiceLocator()
  private init() {
    conferenceData = MRUScheduleDatasource()
    sessionsDataSource = DefaultLazyReadonlySessionsDataSource(dataSource: conferenceData)

    fcmRegistrationService = DefaultFCMRegistrationService()
    userRegistrationService = DefaultUserRegistrationService()
    userState = DefaultPersistentUserState(fcmRegistrationService: fcmRegistrationService,
                                           userRegistrationService: userRegistrationService)
  }

  // MARK: - Conference

  private let conferenceData: MRUScheduleDatasource

  public let sessionsDataSource: LazyReadonlySessionsDataSource

  public func updateConferenceData(_ callback: @escaping () -> Void) {
    conferenceData.subscribeToUpdates { hasChanges in
      if hasChanges {
        self.sessionsDataSource.update()
        self.indexer.updateIndex()
      }
      callback()
    }
  }

  // MARK: - Indexer
  private lazy var indexer: SpotlightIndexer = {
    return SpotlightIndexer(sessionsRepository: self.sessionsDataSource)
  }()

  // MARK: - Bookmarks

  public lazy var bookmarkDataSource: RemoteBookmarkDataSource = {
    let dataSource = RemoteBookmarkDataSource()
    dataSource.syncBookmarks { _ in }
    return dataSource
  }()

  // MARK: - Reservations
  public lazy var reservationDataSource: RemoteReservationDataSource = {
    let dataSource = RemoteReservationDataSource()
    dataSource.observeReservationUpdates { (_, _) in }
    return dataSource
  }()

  // MARK: - User State
  private let fcmRegistrationService: DefaultFCMRegistrationService
  public let userState: PersistentUserState

  // MARK: - User Registration Status
  private let userRegistrationService: UserRegistrationService

}
