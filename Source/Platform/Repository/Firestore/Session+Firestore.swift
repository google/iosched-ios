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

import FirebaseFirestore

extension URL {
  init?(string: String?) {
    guard let string = string, !string.isEmpty else {
      return nil
    }
    self.init(string: string)
  }
}

extension Session {
  public init?(scheduleDetail: QueryDocumentSnapshot) {
    let data = scheduleDetail.data() as [String: Any]
    let id = data["id"] as? String
    let title = data["title"] as? String
    let description = data["description"] as? String
    let startTimestamp = data["startTimestamp"] as? NSNumber
    let endTimestamp = data["endTimestamp"] as? NSNumber
    let room = data["room"] as? [String: Any]
    let roomId = room?["id"] as? String
    let roomName = room?["name"] as? String
    let tags = data["tags"] as? [[String: Any]]
    var eventTags: [EventTag] = []
    if let tags = tags {
      for tag: [String: Any] in tags {
        if let eventTag = EventTag(dictionary: tag) {
          eventTags.append(eventTag)
        }
      }
    }
    var speakers: [Speaker] = []
    if let speakersData = data["speakers"] as? [[String: Any]] {
      for speakerData in speakersData {
        let speakerId = speakerData["id"] as? String
        let speakerName = speakerData["name"] as? String
        let speakerBio = speakerData["bio"] as? String
        let speakerCompany = speakerData["company"] as? String
        let speakerThumbnailURL = URL(string: speakerData["thumbnailURL"] as? String)
        let speakerSocialLinks = (speakerData["socialLinks"] as? [String: Any]) ?? [String: Any]()
        let speakerTwitterURL = URL(string: speakerSocialLinks["Twitter"] as? String)
        let speakerGithubURL = URL(string: speakerSocialLinks["GitHub"] as? String)
        let speakerLinkedInURL = URL(string: speakerSocialLinks["LinkedIn"] as? String)
        let speakerWebsiteURL = URL(string: speakerSocialLinks["Website"] as? String)
        if let speakerId = speakerId,
           let speakerName = speakerName,
           let speakerBio = speakerBio,
           let speakerCompany = speakerCompany {
          let speaker = Speaker(id: speakerId,
                                name: speakerName,
                                bio: speakerBio,
                                company: speakerCompany,
                                thumbnailURL: speakerThumbnailURL,
                                twitterURL: speakerTwitterURL,
                                linkedinURL: speakerGithubURL,
                                githubURL: speakerLinkedInURL,
                                websiteURL: speakerWebsiteURL)
          speakers.append(speaker)
        }
      }
    }
    self.speakers = speakers
    let youtubeURL = data["youtubeUrl"] as? String

    // Check for required fields and abort if missing.
    if let id = id,
       let title = title,
       let description = description,
       let startTimestamp = startTimestamp,
       let endTimestamp = endTimestamp,
       let url = URL(string: "https://events.google.com/io/schedule/events/" + id) {
      self.id = id
      self.url = url
      self.title = title
      self.detail = description
      self.startTimestamp = Date(timeIntervalSince1970: startTimestamp.doubleValue / 1000)
      self.endTimestamp = Date(timeIntervalSince1970: endTimestamp.doubleValue / 1000)
      self.youtubeURL = youtubeURL.flatMap(URL.init(string:))
      self.tags = eventTags
      self.mainTopic = eventTags.filter { $0.type == .topic } .first
      self.roomId = roomId ?? "(unknown)"
      self.roomName = roomName ?? "(TBA)"
    } else {
      print("Malformed data: \(data)")
      return nil
    }
  }

}
