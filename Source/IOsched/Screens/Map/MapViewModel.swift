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
import MapKit
import UIKit

import Domain

enum MapItemType: String {
  case session = "session"
  case plain = "plain"
  case label = "label"
  case codeLab = "codelab"
  case sandbox = "sandbox"
  case officeHours = "officehours"
  case misc = "misc"
  case inactive = "inactive"
  case unknown = "unknown"
  case ada = "icon_ada"
  case bar = "icon_bar"
  case bike = "icon_bike"
  case charging = "icon_charging"
  case dog = "icon_dog"
  case food = "icon_food"
  case info = "icon_info"
  case medical = "icon_medical"
  case parking = "icon_parking"
  case restroom = "icon_restroom"
  case ride = "icon_ride"
  case rideshare = "icon_rideshare"
  case shuttle = "icon_shuttle"
  case store = "icon_store"
  case press = "press"
  case mothersRoom = "mothers_room"
  case communityLounge = "community_lounge"
  case certificationLounge = "certification_lounge"
}

class MapViewModel {

  private enum Constants {
    static let stagesTitle =
        NSLocalizedString("STAGES", comment: "Title for stages section header in map filters.")
    static let sandboxesTitle =
        NSLocalizedString("SANDBOXES", comment: "Title for sandboxes section header in map filters.")
    static let servicesTitle =
        NSLocalizedString("SERVICES", comment: "Title for services section header in map filters.")
  }

  private let conferenceDataSource: ConferenceDataSource

  var map: Map?
  var mapItems = [MapItemViewModel]()
  var filterSections = [FilterSectionViewModel]()

  // Whether any items are checked in the filter list.
  var anyItemsSelected: Bool {
    return filterSections.reduce(false, {(sum, section) in
      return sum || section.items.reduce(false, {(sum, item) in
        return sum || item.selected
      })
    })
  }

  init(conferenceDataSource: ConferenceDataSource) {
    self.conferenceDataSource = conferenceDataSource
  }

  func update(_ callback: @escaping () -> Void) {
    update()
    callback()
  }

  private func update() {
    mapItems = markers()

    filterSections.removeAll()
    let sandboxes = mapItems.filter({$0.type == .sandbox})
    let stages = mapItems.filter({$0.type == .session})
    filterSections.append(FilterSectionViewModel(name: Constants.stagesTitle, items: stages))
    filterSections.append(FilterSectionViewModel(name: Constants.sandboxesTitle, items: sandboxes))
  }

  private func markers() -> [MapItemViewModel] {
    let restroomsName = NSLocalizedString("Restrooms", comment: "Map label title")
    let restroomsDesc1 = NSLocalizedString("Female, gender neutral and male bathrooms.", comment: "Map label description")
    let restroomsDesc2 = NSLocalizedString("Female and male bathrooms.", comment: "Map label description")
    let stageDesc = NSLocalizedString("Attend 40min Sessions throughout the three days of the event. Check the schedule for more details on topics and speakers.", comment: "Map label description")
    let foodDesc = NSLocalizedString("Hungry? This is where you can find food and drinks throughout the event:\n\nDAY 1\n-- Breakfast = Concession stands around the Amphitheatre\n-- Lunch = Concession stands around the Amphitheatre\n-- After Hours = EATS Market\n\nDAY 2\n-- Breakfast = Concession stands around the Amphitheatre\n-- Lunch = EATS Market\n-- After Hours = Concession stands around the Amphitheatre\n\nDAY 3\n-- Breakfast = Concession stands around the Amphitheatre\n-- Lunch = EATS Market\n\nSnacks and water will be available throughout the venue at all times. Check the event agenda for exact meal schedules.\n\nDietary restrictions\nAll Kosher and Halal meals can be picked up across from the entrance to the Press Lounge inside the Concourse. Any other dietary needs will be listed on catering signage at each of the food stands or buffets within the venue - this includes gluten free, dairy free, vegan, and vegetarian.", comment: "Map label description")
    let concessionsName = NSLocalizedString("Concession stand", comment: "Map label title")
    let mothersRoomName = NSLocalizedString("Mother's Room", comment: "Map label title")
    let mothersRoomDesc = NSLocalizedString("Mothers who are nursing are welcome to attend the conference with their child. There will be four first-come, first-served mothers' rooms available throughout the venue. Please see the conference help desk for more information.\n\nThis room will be open on:\n-- May 8: from 8am - 8pm\n-- May 9: from 8am - 8pm\n-- May 10: from 8am - 4pm.", comment: "Map label description")
    let ioStoreName = NSLocalizedString("I/O Store", comment: "Map label title")
    let ioStoreDesc = NSLocalizedString("The store offers a unique collection of Google I/O'18 branded goodies available for purchase, including t-shirts, hoodies, hats, and a signature Android figurine.", comment: "Map label description")
    let markers = [
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.427350, longitude:-122.079176, description: restroomsDesc1),
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.424014, longitude:-122.080043, description: restroomsDesc1),
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.424896, longitude:-122.078668, description: restroomsDesc1),
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.424237, longitude:-122.078791, description: restroomsDesc1),
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.426681, longitude:-122.079575, description: restroomsDesc2),
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.426011, longitude:-122.080135, description: restroomsDesc2),
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.427567, longitude:-122.080352, description: restroomsDesc2),
      MapItemViewModel(name: restroomsName, type: .restroom, latitude:37.426336, longitude:-122.081567, description: restroomsDesc2),
      MapItemViewModel(name: NSLocalizedString("Info Desk", comment: "Map label title"), type: .info, latitude:37.426273, longitude:-122.079774, description: NSLocalizedString("If you have any questions about the event, you can ask the Staff members at the Info Desk for help.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Shuttle Stop", comment: "Map label title"), type: .shuttle, latitude:37.425915, longitude:-122.07676, description: NSLocalizedString("The shuttle service is complimentary for attendees on a first-come, first-served basis. Confirm shuttle stops and the full shuttle schedule on the Attending - Travel page.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Bike Parking", comment: "Map label title"), type: .bike, latitude:37.426229, longitude:-122.077219, description: NSLocalizedString("Bike parking is complimentary for attendees and will be available during event hours.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("ADA Parking", comment: "Map label title"), type: .ada, latitude:37.426179, longitude:-122.077339, description: NSLocalizedString("When arriving to the venue, please follow signs for ADA parking and have your placard hanging from the car mirror and visible to parking employees at all times to expedite the parking process. Accessible parking spaces are readily available on a first-come, first-served basis and may not be reserved in advance to fairly serve all attendees.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Ridesharing drop-off / pick-up", comment: "Map label title"), type: .rideshare, latitude:37.423083, longitude:-122.081111, description: ""),
      MapItemViewModel(name: NSLocalizedString("Medical Station", comment: "Map label title"), type: .medical, latitude:37.425924, longitude:-122.080369, description: NSLocalizedString("If you need any medical assistance throughout the event, please make your way to the Medical station. If you’re unable to commute or you’re not feeling well ask a Staff member for help instead.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Amphitheatre", comment: "Map label title"), type: .plain, latitude:37.4268969, longitude:-122.080725, description: NSLocalizedString("Attend the two Keynotes on May 8: The Google Keynote will feature our latest product and platform innovations led by Sundar Pichai, CEO, Google. The Developer Keynote will focus specifically on updates to our developer products and platforms.\n\nThe Amphitheatre will also host breakout Sessions throughout the three days of the event, and the After Hours concert on Day 2.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Stage 1", comment: "Map label title"), type: .session, latitude:37.425452, longitude:-122.080193, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Stage 2", comment: "Map label title"), type: .session, latitude:37.425041, longitude:-122.080571, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Stage 3", comment: "Map label title"), type: .session, latitude:37.424873, longitude:-122.079643, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Stage 4", comment: "Map label title"), type: .session, latitude:37.423984, longitude:-122.079541, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Stage 5", comment: "Map label title"), type: .session, latitude:37.424410, longitude:-122.078790, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Stage 6", comment: "Map label title"), type: .session, latitude:37.425139, longitude:-122.078591, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Stage 7", comment: "Map label title"), type: .session, latitude:37.426383, longitude:-122.078713, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Stage 8", comment: "Map label title"), type: .session, latitude:37.427164, longitude:-122.079083, description: stageDesc),
      MapItemViewModel(name: NSLocalizedString("Community Lounge", comment: "Map label title"), type: .communityLounge, latitude:37.425720, longitude:-122.080497, description: NSLocalizedString("Hang out with members of the Google Developers Community Groups program, GDGs, Google Developers Experts, Women Techmakers, and Googlers at the Community Lounge.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Certification Lounge", comment: "Map label title"), type: .certificationLounge, latitude:37.425720, longitude:-122.080263, description: NSLocalizedString("Find out what's new in the Google Developers and Cloud Certification programs. Meet Android, Web, and Cloud experts, and learn how you can get certified and gain recognition for your skills as a developer.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox A: Assistant", comment: "Map label title"), type: .sandbox, latitude:37.425639, longitude:-122.079997, description: NSLocalizedString("Learn more about the the Google Assistant platform and its capabilities. Connect with experts on how to build great Actions with Dialogflow and how to integrate your smart devices with the Google Assistant. You can also explore interactive demos built using the latest features of the Google Assistant SDK or just join ongoing lightning talks.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox B: Cloud, Firebase & Flutter", comment: "Map label title"), type: .sandbox, latitude:37.425496, longitude:-122.079646, description: NSLocalizedString("Meet the Google Cloud, Firebase, and Flutter engineers and product leads, and ask them your questions. Try out demos and learn how to build and scale your apps. Just outside this sandbox, you'll also find the Firebase AppShip Launchpad and Flutter Hot Reload multi-player games.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox C: Android & Play", comment: "Map label title"), type: .sandbox, latitude:37.424193, longitude:-122.080082, description: NSLocalizedString("Meet the experts from Android platform, Google Play, Android TV, and Wear OS by Google.\n\nWhat to expect:\n-- Android: The space will showcase the latest version of Android, new features in Android Studio, Kotlin enhancements, and more. Experience how Android makes modern app development quick and easy, while boosting your productivity.\n-- Google Play: Experience the new Android app model of development and distribution on Google Play. Learn how new Google Play Console features can help you boost your app quality and business performance on the Play Store. And play some of the winning games from the global Google Play Indie Games Festivals.\n-- Android TV: You’ll learn about the user experience on the latest version of Android, the Google Assistant integration, and more.\n-- Wear OS by Google: Try the latest smartwatches and learn more about the opportunities to develop for Wear OS by Google.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox D: Android Things & Nest", comment: "Map label title"), type: .sandbox, latitude:37.424295, longitude:-122.079101, description: NSLocalizedString("Learn more about Android Things and Nest and how these products work together to improve every day experiences and help you build for the future.\n\nI/O scavenger hunt\nWhat do machine learning, Android Things, and flowers have in common? Take part in the I/O scavenger hunt to find out! Get started here: <link to hunt website>. (Hint: you may learn that there's an Android Things developer kit waiting for you in your future!)", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox E: AR/VR", comment: "Map label title"), type: .sandbox, latitude:37.424878, longitude:-122.079120, description: NSLocalizedString("Come interact with and learn more about Google's AR and VR platforms: ARCore and Daydream. Discover the latest ARCore features and learn how to implement them in your own app development.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox F: Design & Accessibility", comment: "Map label title"), type: .sandbox, latitude:37.425052, longitude:-122.079051, description: NSLocalizedString("Discover the latest evolution of Material Design—including new features, tools, and code. Then meet with Material experts to optimize your product’s UI. You can also learn more about the Accessibility of many Alphabet products, and get a feel for the innovative potential of designing for persons with disabilities. Attendees will have the chance to have their app or site reviewed by real accessibility users as well as accessibility engineering experts.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox G: Web & Payments", comment: "Map label title"), type: .sandbox, latitude:37.425601, longitude:-122.079210, description: NSLocalizedString("Google is redoubling its commitment to the open web, making it easier and less costly than ever to build great experiences for web users. Come talk to Google engineers – you'll learn how to get the best out of AMP and PWA, how to create amazing AR/VR web content, how to offer highly secure authentication while maintaining a great user experience, how to leverage the latest offerings from Polymer and Angular, and how to speed up your website with Lighthouse and our new performance tools.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox H: Experiments", comment: "Map label title"), type: .sandbox, latitude:37.426589, longitude:-122.078920, description: NSLocalizedString("Since 2009, coders have created thousands of amazing experiments using Chrome, Android, AI, AR, and more. Visit the Experiments Sandbox to check out a few and learn more about how you can submit your own.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox I: AI/Machine Learning", comment: "Map label title"), type: .sandbox, latitude:37.426731, longitude:-122.079047, description: NSLocalizedString("Curious about machine learning (ML) & artifical intelligence (AI)? Come meet AI teams at Google and check out interactive demos to learn more about how AI and ML tools, like TensorFlow, are used in Google products.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox: Android Auto", comment: "Map label title"), type: .sandbox, latitude:37.424272, longitude:-122.079821, description: NSLocalizedString("Swing by the Android Auto Sandbox to see the best of the Google and developer ecosystems for cars, to experience live demos, and to learn how you can develop for these in-car experiences.\n\nWhat to expect:\n-- A brand new media experience for Android Auto, both on your phone screen and on your car display, making it easier and faster than ever before to surface content to users.\n-- An in-car concept with the latest version of Android running as the built-in infotainment platform.\n-- You'll also see developer apps and Google services like Google Maps, the Google Assistant, and Google Play Store, all adapted and optimized for the new automotive interface.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Sandbox: Waymo", comment: "Map label title"), type: .sandbox, latitude:37.425386, longitude:-122.078956, description: NSLocalizedString("Ever since Waymo started as the Google self-driving car project in 2009, they have been working to make roads safer, free up people’s time, and improve mobility for everyone. Come see a past-to-future display of Waymo's self-driving cars, including the iconic Firefly vehicle, the Chrysler Pacifica Hybrid minivan, and an exciting new addition to the fleet—a self-driving Jaguar I-PACE. These vehicles have collectively self-driven over 5 million miles, helping Waymo to build one of the world's most experienced drivers on the road.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Office Hours & App Reviews", comment: "Map label title"), type: .officeHours, latitude:37.426766, longitude:-122.078700, description: NSLocalizedString("Come talk to Googlers about your projects and get answers to your most pressing technical questions. Product teams will be on hand throughout the event during defined time slots; check the event schedule to confirm when the product you’re looking for some help with will be staffed.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Codelabs", comment: "Map label title"), type: .codeLab, latitude:37.426460, longitude:-122.079987, description: NSLocalizedString("Get hands-on with the latest and greatest Google technologies by trying one of over 100 brand-new and updated Codelabs on diverse topics. Our ready-to-code kiosks have everything you need to try one of our self-paced tutorials, or bring your own machine and take your work home with you. Google staff will be on hand to help if you get stuck.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("EATS Market", comment: "Map label title"), type: .food, latitude:37.424420, longitude:-122.0800174, description: foodDesc),
      MapItemViewModel(name: concessionsName, type: .food, latitude:37.426189, longitude:-122.080641, description: foodDesc),
      MapItemViewModel(name: concessionsName, type: .food, latitude:37.426220, longitude:-122.080445, description: foodDesc),
      MapItemViewModel(name: concessionsName, type: .food, latitude:37.426659, longitude:-122.079901, description: foodDesc),
      MapItemViewModel(name: concessionsName, type: .food, latitude:37.426917, longitude:-122.079894, description: foodDesc),
      MapItemViewModel(name: NSLocalizedString("Registration", comment: "Map label title"), type: .info, latitude:37.426061, longitude:-122.077589, description: NSLocalizedString("Pick-up your badge starting on May 7 between 7am - 7pm. Check the event agenda for the badge pick-up schedule on May 8-10.", comment: "Map label description")),
      MapItemViewModel(name: NSLocalizedString("Press Lounge", comment: "Map label title"), type: .press, latitude:37.427259, longitude:-122.079763, description: NSLocalizedString("Reserved for guests with Press badges.", comment: "Map label ")),
      MapItemViewModel(name: mothersRoomName, type: .mothersRoom, latitude:37.426022, longitude:-122.080300, description: mothersRoomDesc),
      MapItemViewModel(name: mothersRoomName, type: .mothersRoom, latitude:37.427273, longitude:-122.079068, description: mothersRoomDesc),
      MapItemViewModel(name: mothersRoomName, type: .mothersRoom, latitude:37.4248565, longitude:-122.078943, description: mothersRoomDesc),
      MapItemViewModel(name: mothersRoomName, type: .mothersRoom, latitude:37.424076, longitude:-122.080229, description: mothersRoomDesc),
      MapItemViewModel(name: ioStoreName, type: .store, latitude:37.426432, longitude:-122.079674, description: ioStoreDesc),
      MapItemViewModel(name: ioStoreName, type: .store, latitude:37.426162, longitude:-122.080100, description: ioStoreDesc)
    ]
    return markers
  }
}

class MapItemViewModel {
  let type: MapItemType
  let id: String
  let title: String
  let longitude: CLLocationDegrees
  let latitude: CLLocationDegrees
  let tag: String?
  let description: String?
  var selected: Bool

  init(feature: MapFeature) {
    type = MapItemType(rawValue: feature.type.lowercased()) ?? MapItemType.unknown
    id = feature.id
    title = feature.title
    description = feature.description
    longitude = CLLocationDegrees(feature.longitude)
    latitude = CLLocationDegrees(feature.latitude)
    tag = feature.tag
    selected = false
  }

  init(name: String, type: MapItemType, latitude: Float, longitude: Float, description: String) {
    self.description = description
    self.longitude = CLLocationDegrees(longitude)
    self.latitude = CLLocationDegrees(latitude)
    title = name
    selected = false
    self.type = type
    self.id = ""
    self.tag = nil
  }
}

class FilterSectionViewModel {
  let name: String
  let items: [MapItemViewModel]
  var expanded: Bool

  init(name: String, items: [MapItemViewModel]) {
    self.name = name
    self.items = items
    expanded = false
  }
}
