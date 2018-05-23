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
import Domain

public final class DefaultServiceLocator: Domain.ServiceLocator {

  // MARK: - Singleton
  public static let sharedInstance = DefaultServiceLocator()
  private init() {
    conferenceData = MRUScheduleDatasource()
    sessionsRepository = DefaultSessionsRepository(datasource: conferenceData)
    roomsRepository = DefaultRoomsRepository(datasource: conferenceData)
    tagsRepository = DefaultTagsRepository(datasource: conferenceData)
    speakersRepository = DefaultSpeakersRepository(datasource: conferenceData)
    mapRepository = DefaultMapRepository(datasource: conferenceData)

    bookmarkRepository = BookmarkRepository(sessionsRepository: sessionsRepository)

    fcmRegistrationService = DefaultFCMRegistrationService()
    userRegistrationService = DefaultUserRegistrationService()
    userState = DefaultWritableUserState(bookmarkRepository: bookmarkRepository,
                                         fcmRegistrationService: fcmRegistrationService,
                                         userRegistrationService: userRegistrationService)

    bookmarkNotificationManager = DefaultBookmarkNotificationManager(userState: userState)
    bookmarkRepository.bookmarkNotificationManager = bookmarkNotificationManager

    reservationrepository = ReservationRepository()
  }

  // MARK: - Conference
  private let conferenceData: MRUScheduleDatasource

  private let sessionsRepository: SessionsRepository
  private let roomsRepository: RoomsRepository
  private let tagsRepository: TagsRepository
  private let speakersRepository: SpeakersRepository
  private let mapRepository: MapRepository
  public lazy var conferenceDataSource: ConferenceDataSource = {
    return DefaultConferenceDataSource(sessionsRepository: self.sessionsRepository,
                                       roomsRepository: self.roomsRepository,
                                       tagsRepository: self.tagsRepository,
                                       speakersRepository: self.speakersRepository,
                                       mapRepository: self.mapRepository)
  }()

  public func updateConferenceData(_ callback: @escaping () -> Void) {
    conferenceData.update { hasChanges in
      if hasChanges {
        let repositories: [UpdatableRepository] = [
          self.sessionsRepository,
          self.roomsRepository,
          self.tagsRepository,
          self.speakersRepository,
          self.mapRepository]
        repositories.forEach { $0.update() }
        self.indexer.updateIndex()
      }
      callback()
    }
  }

  // MARK: - Indexer
  private lazy var indexer: SpotlightIndexer = {
    return SpotlightIndexer(sessionsRepository: self.sessionsRepository,
                            speakersRepository: self.speakersRepository)
  }()

  // MARK: - Bookmarks
  private let bookmarkRepository: BookmarkRepository
  public lazy var bookmarkStore: WritableBookmarkStore = {
    return DefaultWritableBookmarkStore(self.bookmarkRepository,
                                         sessionsRepository: self.sessionsRepository,
                                         userState: self.userState,
                                         bookmarkNotificationManager: self.bookmarkNotificationManager)
  }()

  private let bookmarkNotificationManager: BookmarkNotificationManager

  // MARK: - Reservations
  private let reservationrepository: ReservationRepository
  public lazy var reservationStore: ReadonlyReservationStore = {
    return DefaultReservationStore(self.reservationrepository)
  }()

  // MARK: - User State
  private let fcmRegistrationService: DefaultFCMRegistrationService
  public let userState: WritableUserState

  // MARK: - User Registration Status
  private let userRegistrationService: UserRegistrationService

}
