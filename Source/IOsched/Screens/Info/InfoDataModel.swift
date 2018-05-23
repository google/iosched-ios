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

import Domain

// MARK: - Events

struct Event {
  let title: String
  let icon: UIImage
  let summary: String
  let headerColor: UIColor

  static let events: [Event] = [
    .sandbox,
    .codelabs,
    .officeHours,
    .afterHours
  ]

  static let sandbox = Event(
    title: NSLocalizedString("Sandbox", comment: "Title of the Sandbox event"),
    icon: UIImage(named: "ic_sandbox")!,
    summary: NSLocalizedString("Dedicated spaces to explore, learn, and play with our latest products and platforms via interactive demos, physical installations, and more.", comment: "Short summary of I/O Sandbox event"),
    headerColor: UIColor(red: 0, green: 228 / 255, blue: 1, alpha: 1)
  )

  static let codelabs = Event(
    title: NSLocalizedString("Codelabs", comment: "Title of the Codelabs event"),
    icon: UIImage(named: "ic_codelabs")!,
    summary: NSLocalizedString("Get hands-on experience in our ready-to-code kiosks. Here, you'll have everything you need to learn about the latest and greatest Google technologies via self-paced tutorials, or bring your own machine and take your work home with you. Google staff will be on hand for helpful advice and to provide direction if you get stuck.", comment: "Short summary of I/O Codelabs event"),
    headerColor: UIColor(red: 28 / 255, green: 232 / 255, blue: 181 / 255, alpha: 1)
  )

  static let officeHours = Event(
    title: NSLocalizedString("Office Hours & App Reviews", comment: "Title of the Office Hours & App Reviews event"),
    icon: UIImage(named: "ic_office_hours")!,
    summary: NSLocalizedString("Office Hours are your chance to meet one-on-one with Google experts to ask all your technical questions, and App Reviews will give you the opportunity to receive advice and tips on your specific app-related projects.", comment: "Short summary of I/O Office Hours event"),
    headerColor: UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
  )

  static let afterHours = Event(
    title: NSLocalizedString("After Hours", comment: "Title of the After Hours event"),
    icon: UIImage(named: "ic_after_hours")!,
    summary: NSLocalizedString("After Sessions end for the day, stick around Shoreline for two evenings of food, drinks, and fun. On the first night, the party will take over the Sandbox space, and on the second night, we'll have an exclusive concert in the Amphitheatre.", comment: "Short summary of I/O After Hours event"),
    headerColor: UIColor(red: 188 / 255, green: 200 / 255, blue: 251 / 255, alpha: 1)
  )
}

// MARK: -

struct InfoDetail {

  /// The title to be displayed above the detail view's contents. The detail view
  /// doesn't actually display this, but exposes it for its container to display.
  let title: String

  /// The detail text to be displayed by the detail view. This text should be localized
  /// and can contain some HTML, but not HTML tables. Displayed in a UITextView as an
  /// attributed string.
  let detail: String

}

// MARK: - Travel

extension InfoDetail {

  static let shuttleService = InfoDetail(
    title: NSLocalizedString("Shuttle service", comment: "Title of the Shuttle Service cell"),
    detail:NSLocalizedString("<p>Event shuttles will be provided at no charge to all Google I/O attendees from all Google-recommended hotels. There is also select service from San Francisco and other locations along the Peninsula. <strong>You must show your Google I/O confirmation email or conference badge to board all Google I/O event shuttles.</strong></p><p>Each pick-up location can have ADA accessible vehicles. Please indicate on your registration form if you have any ADA or special assistance requirements, and the planning team will follow up with you directly.</p>", comment: "Localized HTML describing I/O's shuttle service")
  )

  static let carpool = InfoDetail(
    title: NSLocalizedString("Parking and carpooling", comment: "Title of the Carpool and Parking cell"),
    detail: NSLocalizedString("<p>Parking is very limited and available only in the Google I/O designated lots located across from Shoreline Amphitheatre along Shoreline Boulevard.\n\nThere is no event parking along Amphitheatre Parkway or Charleston Road. If you plan to drive, we recommend carpooling with other attendees due to limited parking availability at the venue. Preferred parking spaces will be available for cars containing 2 or more people.</p>", comment: "Localized HTML describing I/O's parking availability and location")
  )

  static let publicTransportation = InfoDetail(
    title: NSLocalizedString("Public transportation", comment: "Title of the Public Transportation cell"),
    detail: NSLocalizedString("<p><strong>Public transportation to the area is accessible via:</strong></p>"
      + "<p>"
      +   "<a href='http://www.caltrain.com/'>CALTRAIN</a>\tRegional rail system <br />"
      +   "<a href='http://www.vta.org/getting-around/interactive-light-rail-map'>VTA</a>\tLight rail system servicing the South Bay <br />"
      +   "<a href='https://www.bart.gov/'>BART</a>\t\tBay Area Rapid Transit <br />"
      + "</p>"
      + "<p>"
      + "Public transit doesn’t go directly to Google I/O. Check the shuttle section to confirm if shuttles will be offered in your location."
      + "</p>", comment: "Localized HTML presenting a short summary of Caltrain, BART, and VTA")
  )

  static let biking = InfoDetail(
    title: NSLocalizedString("Biking", comment: "Title of the Biking cell"),
    detail: NSLocalizedString("<p>Complimentary bike parking will be available at Shoreline Amphitheatre in Parking Lot A. The Silicon Valley Bicycle Coalition will provide secure valet parking for your bicycle from 7am until the event ends each day. There are two trails, Stevens Creek Trail and Permanente Creek Trail, that are convenient for bike riders heading to Shoreline Amphitheatre. Check Google Maps for the best bike routes and directions.</p><p>The Bay Area Bike to Work Day is scheduled on Thursday, May 10th.  There will be thousands of cyclists participating near Shoreline and there are hundreds of energizer stations throughout the area.  Please check out the <a href=\"https://bikesiliconvalley.org/btwd/\">Silicon Valley Bike to Work Day website</a> for more information.</p>", comment: "Localized HTML summarizing Bay Area Bike Share, bike parking, and I/O bike accessibility")
  )

  static let rideShare = InfoDetail(
    title: NSLocalizedString("Ridesharing", comment: "Title of the Ride Sharing cell"),
    detail: NSLocalizedString("<p><strong>Waze Carpool</strong></p><p>Waze Carpool is a trusted community of drivers and riders that is available to make your Google I/O commute fun, fast and affordable. Driving? Open <a href=\"https://Waze.com/get\">Waze</a> when you get to the Bay Area. Looking for a ride? Install <a href=\"https://Waze.com/carpool\">Waze Carpool</a> before you arrive.</p><blockquote><p><strong>Promo code:</strong> WAZEIO18<br><small>Code enables free rides for Waze Carpool riders to and from Google I/O on May 7-10, 2018. Go to \"Settings > Payment method > Enter promo code\" in the Waze Carpool app to redeem.</small></p></blockquote><p><strong>Lyft Line</strong></p><p>Download the Lyft app from the <a href=\"https://itunes.apple.com/us/app/lyft-taxi-app-alternative/id529379082?mt=8\">App Store</a> and use Lyft Line to share a ride with others going the same way.</p><blockquote><p><strong>Discount code:</strong> Googleio18<br><small>This code is valid from May 8-10, 2018 for shared rides with Lyft Line. It’s redeemable for up to $10 per trip and for up to 250 users per day. Rides must begin or end at Shoreline Amphitheatre.</small></p></blockquote><p><strong>Passenger pick-up and drop-off</strong></p><p>The pick-up and drop-off location will be confirmed soon.</p>", comment: "Localized HTML summarizing Lyft and Uber offerings for ride sharing to I/O")
  )

  static let travelDetails: [InfoDetail] = [
    .shuttleService,
    .carpool,
    .publicTransportation,
    .biking,
    .rideShare
  ]

}

// MARK: - FAQ screen

extension InfoDetail {

  static let datesAndLocation = InfoDetail(
    title: NSLocalizedString("When and where is Google I/O 2018?", comment: "2018 Dates and Location title"),
    detail: NSLocalizedString("The 2018 developer festival will be held from May 8 – 10 at Shoreline Amphitheatre in Mountain View, California.", comment: "Localized text describing I/O event dates and location")
  )

  static let stayInformed = InfoDetail(
    title: NSLocalizedString("How can I stay informed on the latest about I/O?", comment: "Catch-all title for any content generally I/O-related, like social media"),
    detail: NSLocalizedString("<p>To stay up-to-date on the latest information on sessions, speakers, and overall activities, be sure to frequently visit the <a href=\"https://events.google.com/io/\">Google I/O 2018 website</a>, the <a href=\"https://developers.googleblog.com/\">Google Developers Blog</a>, and follow us on <a href=\"https://twitter.com/googledevs\">Twitter</a>, <a href=\"https://www.facebook.com/Google-Developers-967415219957038/\">Facebook</a>, and <a href=\"https://plus.google.com/+GoogleDevelopers\">Google+</a>. You can also follow and join the social conversation about Google I/O 2018 via the official <a href=\"https://twitter.com/search?q=%23io18&amp;src=typd\">#io18</a> hashtag. In addition, we'll be emailing important information to all registered attendees, along with check-in instructions prior to the festival.</p><p>If you'd like to receive information from Google about products and activities relevant to developers including invitations to private betas, product research, and newsletters, fill out <a href=\"https://docs.google.com/forms/d/e/1FAIpQLSe8KYdQaO1Roavu1tr9F9XsdUsBJl_9b5R10CEIczIBDCwmaA/viewform\">this form</a>.</p>", comment: "Localized HTML endorsing I/O's online presence")
  )

  static let liveStreamAndRecordings = InfoDetail(
    title: NSLocalizedString("Will the Sessions be livestreamed? What if I can’t follow the event in real time?", comment: "Livestream and Recordings title"),
    detail: NSLocalizedString("<p>The two Keynotes and all Sessions will be livestreamed on the event website’s homepage during the three days of the festival. If you’re busy at work or on the other side of the planet with a tricky time difference, you can watch the session recordings later on the <a href=\"https://www.youtube.com/user/GoogleDevelopers\">Google Developers YouTube channel</a>.</p>", comment: "Localized HTML describing video options for remote attendees")
  )

  static let language = InfoDetail(
    title: NSLocalizedString("Will all the sessions be in English?", comment: "Question on what language will be used in sessions"),
    detail: NSLocalizedString("Yes. This will allow our global audience to follow along.", comment: "Text affirming all sessions will be in English")
  )

  static let badgePickup = InfoDetail(
    title: NSLocalizedString("Where and when can I pick up my badge?", comment: "Badge pickup question"),
    detail: NSLocalizedString("<p>To expedite the check-in process, we’ll begin badge pickup on Monday, May 7, at Shoreline Amphitheatre. To give you your Google I/O badge, we’ll need to:</p><ul><li>Verify your photo ID. We’re OK with government-issued licenses, passports, and other forms of identification. If you don’t have proper identification, you won’t be able to receive a badge and won’t be admitted into the conference. The name on your ID needs to be an exact match of your registration profile. If you’re an Academic attendee, please remember to bring proof of eligibility.</li><li>Scan your registration QR code received via email. You can scan it from your phone—no need to print the email! #savetheenvironment</li></ul><p>Please note, you may not share, give, or otherwise provide your badge to anyone. Google I/O badges aren’t replaceable, so don't lose yours or you won’t be readmitted to the conference. You must wear your Google I/O badge to gain admission to Google I/O, including the Sessions, Sandboxes, and After Hours. If requested by security, please display or provide additional identification. Google I/O badges may include your name, company or organization (if provided), and photo.</p>", comment: "Instructions for badge pickup")
  )

  static let keynoteSeating = InfoDetail(
    title: NSLocalizedString("I really want a front row seat for the keynote. Tips?", comment: "Question on how keynote seating is handled"),
    detail: NSLocalizedString("Everyone is guaranteed a seat for the Keynotes, but the best seats will be assigned on a first-come, first-served basis during badge pickup beginning at 7am on May 7th. So make sure to come by early!", comment: "Text describing how keynote seating is assigned")
  )

  static let dressCode = InfoDetail(
    title: NSLocalizedString("What should I wear?", comment: "Question on dress expectations"),
    detail: NSLocalizedString("Google I/O is an outdoor developer event, so please be comfortable and casual. There is no enforced dress code. The Bay Area can get very hot during the day and chilly in the evenings, so take this into consideration when planning your attire.", comment: "Text describing what best to wear at I/O")
  )

  static let foodOptions = InfoDetail(
    title: NSLocalizedString("I like to snack. Often. What are my food options onsite?", comment: "Question on food options"),
    detail: NSLocalizedString("Attendees are offered complimentary breakfast, lunch, and snacks on all three days of the conference. Dinner will also be available on Day 1 and 2 during the After Hours events.", comment: "Text describing food provided at I/O")
  )

  static let lostAndFound = InfoDetail(
    title: NSLocalizedString("If I lose anything onsite, where can I find it?", comment: "Question on lost and found"),
    detail: NSLocalizedString("We got your back! The lost & found station will be located at the Conference Help Desk during event hours. Any items left overnight will be turned over to the Conference Security Office. One important detail: Google I/O badges aren’t replaceable, so don't lose yours or you won’t be readmitted to the conference!", comment: "Text describing food provided at I/O")
  )

  static let additionalInfo = InfoDetail(
    title: NSLocalizedString("Additional Info", comment: "Title representing any information that doesn't fir in the above categories"),
    detail: NSLocalizedString("<p>Find additional info on Badge Pick-up, Accessibility, Conduct Policy, Child Care, Mothers' Rooms, and more on the <a href='https://events.google.com/io/faq/'>I/O website</a>.</p>", comment: "Short description and link to the official I/O website, where the full FAQ text is available")
  )

  static let faqDetails: [InfoDetail] = [
    .datesAndLocation,
    .stayInformed,
    .liveStreamAndRecordings,
    .language,
    .badgePickup,
    .keynoteSeating,
    .dressCode,
    .foodOptions,
    .lostAndFound,
    .additionalInfo
  ]

}

extension InfoDetail: Equatable {}
func ==(lhs: InfoDetail, rhs: InfoDetail) -> Bool {
  return lhs.title == rhs.title && lhs.detail == rhs.detail
}

// MARK: - Settings

final class SettingsViewModel {

  private let userState: WritableUserState
  private let notificationPermissions: NotificationPermissions

  // The viewmodel does not guarantee its view controller is alive when
  // it needs to present things.
  weak var presentingViewController: UIViewController?

  init(userState: WritableUserState, presentingViewController: UIViewController? = nil) {
    self.userState = userState
    self.notificationPermissions = NotificationPermissions(userState: userState,
                                                           application: .shared)
    self.presentingViewController = presentingViewController
  }

  var isEventsInPacificTime: Bool {
    get {
      return userState.isEventsInPacificTime
    }
    set {
      userState.setEventsInPacificTime(newValue)
    }
  }

  var isNotificationsEnabled: Bool {
    get {
      return notificationPermissions.isNotificationsEnabled
    }
    set {
      notificationPermissions.isNotificationsEnabled = newValue
    }
  }

  var hasNotificationPermissions: Bool {
    return notificationPermissions.arePermissionsGranted
  }

  /// Closure is retained until the callback is invoked, and then discarded afterward.
  func setNotificationsEnabled(_ newValue: Bool, completion: ((Bool) -> Void)? = nil) {
    notificationPermissions.setNotificationsEnabled(newValue, completion: completion)
  }

  func presentSettingsDeepLinkAlert(cancelHandler: ((UIAlertAction?) -> Void)? = nil) {
    guard let presenter = presentingViewController else { return }

    // Code adapted from NatashaTheRobot's blog https://www.natashatherobot.com/ios-taking-the-user-to-settings/
    let title = NSLocalizedString("Enable Notifications", comment: "Alert title")
    let message = NSLocalizedString("I/O 17 needs your permission to send notifications. Enable these permissions in the Settings app.", comment: "Alert description")
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Name of Settings app"),
                                       style: .`default`) { _ in
      if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.shared.openURL(appSettings)
      }
    }
    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert dismissal button"),
                                     style: .cancel,
                                     handler: cancelHandler)

    alertController.addAction(settingsAction)
    alertController.addAction(cancelAction)

    presenter.present(alertController, animated: true, completion: nil)
  }

  var isAnalyticsEnabled: Bool {
    get {
      return userState.isAnalyticsEnabled
    }
    set {
      userState.setAnalyticsEnabled(newValue)
    }
  }

  func toggleEventsInPacificTime() {
    isEventsInPacificTime = !isEventsInPacificTime
  }

  func toggleNotificationsEnabled() {
    isNotificationsEnabled = !isNotificationsEnabled
  }

  func toggleAnalyticsEnabled() {
    isAnalyticsEnabled = !isAnalyticsEnabled
  }

}
