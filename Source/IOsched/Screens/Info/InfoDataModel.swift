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

// MARK: - Events

struct Event {
  let title: String
  let icon: UIImage
  let summary: String
  let headerColor: UIColor

  static let events: [Event] = [
    .sandbox,
    .officeHours,
    .codelabs,
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
    icon: UIImage(named: "ic_info_codelabs")!,
    summary: NSLocalizedString("Get hands-on experience in our ready-to-code kiosks. Here, you'll have everything you need to learn about the latest and greatest Google technologies via self-paced tutorials, or bring your own machine and take your work home with you. Google staff will be on hand for helpful advice and to provide direction if you get stuck.", comment: "Short summary of I/O Codelabs event"),
    headerColor: UIColor(red: 28 / 255, green: 232 / 255, blue: 181 / 255, alpha: 1)
  )

  static let officeHours = Event(
    title: NSLocalizedString("Office Hours and App Reviews", comment: "Title of the Office Hours & App Reviews event"),
    icon: UIImage(named: "ic_office_hours")!,
    summary: NSLocalizedString("Office Hours are your chance to meet one-on-one with Google experts to ask all your technical questions, and App Reviews give you the opportunity to receive advice and tips on your specific app-related projects.", comment: "Short summary of I/O Office Hours event"),
    headerColor: UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
  )

  static let afterHours = Event(
    title: NSLocalizedString("After Dark", comment: "Title of the After Dark event"),
    icon: UIImage(named: "ic_after_hours")!,
    summary: NSLocalizedString("After sessions end for the day, stick around Shoreline for two evenings of food, drinks, and fun. On the first night, an experimental celebration will take over I/O, and on the second night, we'll have an exclusive concert in the Amphitheatre.", comment: "Short summary of I/O After Dark event"),
    headerColor: UIColor(red: 188 / 255, green: 200 / 255, blue: 251 / 255, alpha: 1)
  )
}

// MARK: -

public struct InfoDetail {

  /// The title to be displayed above the detail view's contents. The detail view
  /// doesn't actually display this, but exposes it for its container to display.
  public let title: String

  /// The detail text to be displayed by the detail view. This text should be localized
  /// and can contain some HTML, but not HTML tables. Displayed in a UITextView as an
  /// attributed string.
  public let detail: String

  private static var attributedDescriptions: [String: NSAttributedString] = [:]

  public func attributedDescription() -> NSAttributedString? {
    return InfoDetail.attributedText(detail: detail)
  }

  public static func attributedText(detail: String) -> NSAttributedString? {
    if notificationObserver == nil {
      registerForDynamicTypeUpdates()
    }
    if let attributed = InfoDetail.attributedDescriptions[detail] {
      return attributed
    }

    guard let data = detail.data(using: .unicode) else {
      return nil
    }
    let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
    guard let attributed = try? NSMutableAttributedString(data: data,
                                                          options: options,
                                                          documentAttributes: nil) else {
                                                            return nil
    }
    // Replace the default font (Times New Roman) with San Francisco font.
    attributed.enumerateAttribute(.font,
                                  in: NSRange(location: 0, length: attributed.length),
                                  options: []) { (attr, range, _) in
      if let oldFont = attr as? UIFont {
        attributed.removeAttribute(.font, range: range)

        if let newFontDescriptor = UIFont.preferredFont(forTextStyle: .callout)
          .fontDescriptor.withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits) {
          let newFont = UIFont(descriptor: newFontDescriptor, size: 0)
          attributed.addAttributes([.font: newFont], range: range)
        }
      }
    }
    InfoDetail.attributedDescriptions[detail] = attributed

    return attributed.copy() as? NSAttributedString
  }

  private static var notificationObserver: Any?

  private static func registerForDynamicTypeUpdates() {
    notificationObserver = NotificationCenter.default
        .addObserver(forName: UIContentSizeCategory.didChangeNotification,
                     object: nil,
                     queue: nil,
                     using: dynamicTypeTextSizeDidChange(_:))
  }

  private static func dynamicTypeTextSizeDidChange(_ notification: Any) {
    // Rebuild existing strings with new font.
    let invalidatedStrings = attributedDescriptions.keys
    attributedDescriptions.removeAll(keepingCapacity: true)
    for string in invalidatedStrings {
      _ = attributedText(detail: string)
    }
  }

}

// MARK: - Travel

extension InfoDetail {

  public static let whatToBring = InfoDetail(
    title: NSLocalizedString("What to bring for the event", comment: "Short blurb describing what attendees should bring to I/O"),
    detail: NSLocalizedString("<p>Google I/O is an outdoor festival. While this is a big part of what makes I/O special, it also means there are some things to consider. Sessions will happen inside climate-controlled tents, but sunscreen, sunglasses, and an extra layer for the evening are recommended. I/O is a casual event, so keep this in mind when deciding what to wear.<br /><br /><strong>Hotels</strong><br />We have room blocks at many local hotels. The list of hotels and room availability will be updated regularly. Please use the map below to find the hotel that's best for you.<br /><a href=\"https://www.google.com/maps/d/u/1/viewer?mid=11u43dDY9LID1uf46p4y7ba2_TbE_Y8-W&ll=37.383600316075075%2C-122.07007405000002&z=12\">Hotel Map</a></p>", comment: "Localized HTML describing what to bring to the event. When localizing, please preserve the html tags.")
  )

  public static let gettingToMountainView = InfoDetail(
    title: NSLocalizedString("Getting to Mountain View", comment: "Short blurb describing how to get to Mountain View via airport"),
    detail: NSLocalizedString("<p>Here are the three major airports in the Bay Area with international airline service:<br /><a href=\"https://www.google.com/maps/dir/San+Francisco+International+Airport,+San+Francisco,+CA+94128/Shoreline+Amphitheatre,+Amphitheatre+Parkway,+Mountain+View,+CA/@37.5206703,-122.3803144,11z/data=!3m1!4b1!4m18!4m17!1m5!1m1!1s0x808f778c55555555:0xa4f25c571acded3f!2m2!1d-122.3789554!2d37.6213129!1m5!1m1!1s0x808fb9f776f5e165:0x1ddf014a1b553f3d!2m2!1d-122.0807647!2d37.4267703!2m3!6e0!7e2!8j1463556000!3e0?hl=en\">San Francisco International Airport (SFO)</a><br />~24 miles<br /><a href=\"https://www.google.com/maps/dir/Oakland+International+Airport,+Oakland,+CA/Shoreline+Amphitheatre,+Amphitheatre+Parkway,+Mountain+View,+CA/@37.5755915,-122.270249,11z/data=!3m1!4b1!4m18!4m17!1m5!1m1!1s0x808f845402c0a641:0xb0630c0f03017460!2m2!1d-122.2197428!2d37.7125689!1m5!1m1!1s0x808fb9f776f5e165:0x1ddf014a1b553f3d!2m2!1d-122.0807647!2d37.4267703!2m3!6e0!7e2!8j1463556000!3e0?hl=en\">Oakland International Airport (OAK)</a><br />~32 miles<br /><a href=\"https://www.google.com/maps/dir/San+Jose+International+Airport-Sjc,+Airport+Boulevard,+San+Jose,+CA,+United+States/Shoreline+Amphitheatre,+Amphitheatre+Parkway,+Mountain+View,+CA/@37.3954744,-122.0741791,12z/data=!3m1!4b1!4m18!4m17!1m5!1m1!1s0x808fcbc3fab3c59b:0xbcfa443f6df67e3e!2m2!1d-121.9289375!2d37.3639472!1m5!1m1!1s0x808fb9f776f5e165:0x1ddf014a1b553f3d!2m2!1d-122.0807647!2d37.4267703!2m3!6e0!7e2!8j1463556000!3e0?hl=en\">San Jose International Airport (SJC)</a><br />~12 miles</p>", comment: "Localized HTML describing how to get to Mountain View. When localizing, please preserve the html tags and convert miles to kilometers in appropriate locales. If in doubt, list both miles and kilometers.")
  )

  public static let gettingToShoreline = InfoDetail(
    title: NSLocalizedString("Getting to Shoreline Amphitheatre", comment: "Short blurb describing how to navigate to Shoreline Amphitheatre"),
    detail: NSLocalizedString(
      """
      <p>
      In an effort to reduce traffic congestion and reduce our carbon emissions, Google I/O 2019 has committed to be a "No Parking Event*." This decision has been carefully considered and we are offering you many free options to arrive at the event without requiring a vehicle.

      We will be providing more information as the event approaches.

      *Accessibility parking will be available.
      </p><br />
      <p><strong>Shuttle service</strong></p>
      <p>
      Free event shuttles from all Google recommended hotels will be provided for Google I/O attendees. There will also be select service from San Francisco, Millbrae BART, Mountain View Caltrain, San Jose, and Oakland. We are increasing the shuttle frequency and capacity at the Mountain View Caltrain and Millbrae Bart stations. Check back closer to the event for pick-up schedules and additional shuttle pickup locations. The Shuttle Schedule  will be posted closer to the event.
      </p>
      <p>
      Free off-site parking will be provided at <a href="https://www.sjearthquakes.com/avayastadium/parking-directions">Avaya Stadium</a>. Shuttles from Avaya will be provided to/from Google I/O.
      </p>
      <p>
      Please indicate on your registration form if you have any ADA or special assistance requirements, and the planning team will follow up with you directly.
      </p><br />
      <p><strong>Public transportation</strong></p>
      <p>
      We will offer prepaid public transit passes that will be available for pickup during preregistration. Public transportation to the area is accessible via:
      <ul>
        <li><a href="http://www.caltrain.com/">Caltrain</a>: Regional rail system</li>
        <li><a href="http://www.vta.org/getting-around/interactive-light-rail-map">VTA</a>: Light rail system servicing the South Bay</li>
        <li><a href="https://www.bart.gov/">BART</a>: Bay Area Rapid Transit</li>
        <li><a href="https://www.amtrak.com/home.html">AMTRAK</a>: Regional rail system</li>
      </ul>

      Public transit doesn't go directly to Google I/O. Stay tuned for the exact transportation locations serviced by Google I/O event shuttles.
      </p>
      <p><strong>Biking</strong></p>
      <p>
      Complimentary bike parking will be available at Shoreline Amphitheatre in Parking Lot A. The Silicon Valley Bicycle Coalition will provide secure valet parking for your bicycle from 7am until the event ends each day.
      </p>
      <p>
      Check Google Maps for the best bike routes and directions. There are two trails, Stevens Creek Trail and Permanente Creek Trail, that are convenient for bike riders heading to Shoreline Amphitheatre.
      </p><br />

      <p><strong>Ridesharing</strong></p>
      <p>
      We will be offering partially subsidized use of Lyft Shared and Uber Pool to/from Shoreline with the code IO2019. You can redeem this code as long as your destination or pick up is Shoreline Amphitheatre.
      </p>
      <p>
      <strong>Lyft Share</strong>: Download the <a href="https://itunes.apple.com/us/app/lyft-taxi-app-alternative/id529379082?mt=8">Lyft app</a> and use Lyft Shared using Code: IO2019 with a $15 credit per ride.
      </p>
      <p>
      <strong>uberPOOL</strong>: Download the <a href="https://itunes.apple.com/us/app/uber/id368677368?mt=8">Uber app</a> to use uberPOOL and share a ride using the <a href="https://r.uber.com/LYMijgu98T">Uber Voucher Link</a>.
      </p>
      <p>
      <strong>Airport Transfers</strong>: Airport transfers to SFO and SJC from Google I/O will be provided on the last day of the event. Airport transfers will NOT be provided on any other dates.
      </p>
      """,
      comment: "Localized HTML describing how to get to Mountain View from within the Bay Area. When localizing, please preserve the html tags.")
  )

  public static let travelDetails: [InfoDetail] = [
    .whatToBring,
    .gettingToMountainView,
    .gettingToShoreline
  ]

}

// MARK: - FAQ screen

extension InfoDetail {

  public static let datesAndLocation = InfoDetail(
    title: NSLocalizedString("When and where is Google I/O 2019?", comment: "2019 Dates and Location title in the form of a question."),
    detail: NSLocalizedString("The 2019 developer festival will be held from May 7 - 9 at Shoreline Amphitheatre in Mountain View, California.", comment: "Localized text describing I/O event dates and location")
  )

  public static let stayInformed = InfoDetail(
    title: NSLocalizedString("How can I stay informed on the latest from Google I/O?", comment: "Catch-all title for any content generally I/O-related, like social media"),
    detail: NSLocalizedString("<p>To stay up-to-date on the latest information on Sessions, speakers, and overall activities, be sure to frequently visit the <a href=\"https://events.google.com/io/\">Google I/O 2019 website</a>, the <a href=\"http://googledevelopers.blogspot.com/\">Google Developers Blog</a>, and follow us on <a href=\"https://twitter.com/googledevs\">Twitter</a> and <a href=\"https://www.facebook.com/Google-Developers-967415219957038/\">Facebook</a>. You can also follow and join the social conversation about Google I/O 2019 via the official <a href=\"https://twitter.com/search?q=%23io19&src=typd\">#io19</a> hashtag. In addition, we'll be emailing important information to all registered attendees, along with check-in instructions prior to the festival.</p>", comment: "Localized HTML endorsing I/O's online presence")
  )

  public static let language = InfoDetail(
    title: NSLocalizedString("Will all the sessions be in English?", comment: "Question on what language will be used in sessions"),
    detail: NSLocalizedString("Yes. This will allow our global audience to follow along.", comment: "Text affirming all sessions will be in English")
  )

  public static let reservations = InfoDetail(
    title: NSLocalizedString("Can I reserve Sessions ahead of the event?", comment: "Question on whether or not sessions can be reserved"),
    detail: NSLocalizedString("Starting in April, in-person attendees can reserve seats for Sessions in advance of the event on the I/O website and also via the I/O mobile app (note: a portion of Session seats will be exempt from reservations and available first-come, first-served onsite). Attendance at Codelabs, App Reviews, and Office Hours is on a first-come, first-served basis onsite.", comment: "Text confirming sessions are reservable but other types of events are not")
  )

  public static let travel = InfoDetail(
    title: NSLocalizedString("What's the best way to get to Shoreline Amphitheatre?", comment: "Question on how to find travel information"),
    detail: NSLocalizedString("Check out the Transportation tab for all the transportation tips you need, including shuttle information, driving and biking directions, ride sharing tips, and more!", comment: "FAQ answer pointing users to the Transportation tab. 'Transportation' should be presented as the name of a screen in the app.")
  )

  public static let badgePickup = InfoDetail(
    title: NSLocalizedString("Where and when can I pick up my badge?", comment: "Badge pickup question"),
    detail: NSLocalizedString("<p>To expedite the check-in process, we'll begin badge pickup on Monday, May 6, at Shoreline Amphitheatre. To give you your Google I/O badge, we'll need to:</p><ul><li>Verify your photo ID. We're OK with government-issued licenses, passports, and other forms of identification. If you don't have proper identification, you won't be able to receive a badge and won't be admitted into the conference. The name on your ID needs to be an exact match of your registration profile. If you're an Academic attendee, please remember to bring proof of eligibility.</li><li>Scan your registration QR code received via email. You can scan it from your phone&mdash;no need to print the email! #savetheenvironment</li></ul><p>Please note, you may not share, give, or otherwise provide your badge to anyone. Google I/O badges aren't replaceable, so don't lose yours or you won't be readmitted to the conference. You must wear your Google I/O badge to gain admission to Google I/O, including the Sessions, Sandboxes, and After Hours. If requested by security, please display or provide additional identification. Google I/O badges may include your name, company or organization (if provided), and photo.</p>", comment: "Instructions for badge pickup")
  )

  public static let keynoteSeating = InfoDetail(
    title: NSLocalizedString("I really want a front row seat for the keynote. Tips?", comment: "Question on how keynote seating is handled"),
    detail: NSLocalizedString("Everyone is guaranteed a seat for the Keynotes, but the best seats will be assigned on a first-come, first-served basis during badge pickup beginning at 7am on May 6th. So make sure to come by early!", comment: "Text describing how keynote seating is assigned")
  )

  public static let dressCode = InfoDetail(
    title: NSLocalizedString("What should I wear?", comment: "Question on dress expectations"),
    detail: NSLocalizedString("Google I/O is an outdoor developer event, so please be comfortable and casual. There is no enforced dress code. The Bay Area can get very hot during the day and chilly in the evenings, so take this into consideration when planning your attire.", comment: "Text describing what best to wear at I/O")
  )

  public static let foodOptions = InfoDetail(
    title: NSLocalizedString("I like to snack. What are my onsite food options?", comment: "Question on food options"),
    detail: NSLocalizedString("Good news, we like food, too!  Attendees are offered complimentary breakfast, lunch, and snacks on all three days of the conference. Dinner will also be available on Day 1 and 2 during the After Hours events.", comment: "Text describing food provided at I/O")
  )

  public static let lostAndFound = InfoDetail(
    title: NSLocalizedString("If I lose something onsite, where can I find it?", comment: "Question on lost and found"),
    detail: NSLocalizedString("We got your back! The lost and found station will be located at the Conference Information Desk during event hours. Any items left overnight will be turned over to the Conference Security Office. One important detail: Google I/O badges are NOT replaceable, so don't lose yours or you won't be readmitted to the conference.", comment: "Text describing food provided at I/O")
  )

  public static let afterDark = InfoDetail(
    title: NSLocalizedString("The After Dark programs sound like fun. Should I go?", comment: "Question asking if the attendee/user should go to After Dark. After Dark should be presented as a title/proper noun."),
    detail: NSLocalizedString("These are two nights you don't want to miss! Attendees are invited to enjoy music, games, and more during the evening of May 8, and to an exclusive concert in the Amphitheatre on May 9. Food and drinks will be available on both nights (alcoholic beverages available for those 21 and over). Both After Hours events are hosted at Shoreline Amphitheatre, and your attendee badge is required for entrance.", comment: "Short description of After Dark events and why the user might want to go.")
  )

  public static let accessibility = InfoDetail(
    title: NSLocalizedString("Can you accommodate my accessibility needs?", comment: "Question asking for details on accessible conference accommodations."),
    detail: NSLocalizedString(
      """
      Google strives to make events open and accessible to everyone, regardless of disability or special needs. Participants with disabilities and/or special needs should provide details in the registration form and/or by emailing us at io19@google.com. This information will be kept private and will be distributed only to the individuals who need to know it to accommodate your request. Otherwise, please approach the Help Desk at Google I/O if you need assistance or have questions about accessibility during the event.

      Shoreline Amphitheatre is an entirely outdoor venue. While the Keynotes will be taking place in an open-air amphitheatre, the Sessions will take place in enclosed areas. All areas of the venue are accessible for wheelchair users, and there will be a limited number of wheelchairs available on a first-come, first-served basis. Wheelchairs can be checked out at the First Aid station and returned at the end of each day. Additionally, there will be a service dog relief area.

      We'll provide live real-time transcription (CART) for the Keynotes and Sessions. Caption text displayed on a large screen at the front of the room will be accessible to all attendees. We'll also use the text to provide captions for our livestream and post-event recordings.
      If you need an ASL interpreter to accompany you in the Sessions at Google I/O, please let us know during registration and we'll be happy to provide one for you. We'll do our best to find a technical translator who is familiar with the domain, but please keep in mind that the interpreter probably won't be able to meet with the speakers beforehand.

      ADA parking spaces will be available. When arriving at the venue, please follow signs for ADA parking. Please have your placard hanging from your rearview mirror and visible to parking employees at all times to expedite the parking process. Accessible parking spaces are readily available on a first-come, first-served basis and may not be reserved in advance to fairly serve all attendees.
      """, comment: "General information for attendees with accessibility requirements")
  )

  public static let mothers = InfoDetail(
    title: NSLocalizedString("How do you support expectant mothers and parents attending I/O?", comment: "Question asking for details on parental accommodations."),
    detail: NSLocalizedString(
      """
      We'll have expectant mother parking spaces in the ADA area.
      Mothers who are nursing are welcome to attend the conference with their child. There will be four mothers' rooms open on May 7 and 8 from 8am - 8pm and on May 9 from 8am - 4pm. Sign up sheets will be available in front of the mothers' rooms and usage is first-come, first-served. Please see the conference help desk for more information.

      Childcare reimbursement of USD $100 per day (not exceeding USD $300 total) will be offered to parents attending that express interest in childcare via our registration form, and is available on a first-come, first-served basis. Our childcare reimbursement is offered through a third-party vendor. If your request for childcare is approved by us via email before the conference starts and your onsite attendance is confirmed, our vendor will reach out to you with next steps within 7 business days following Google I/O. They will manage all disbursement of our childcare disbursement.
      """, comment: "General information for attendees with parental accommodation or childcare requirements")
  )

  public static let antiHarassmentPolicy = InfoDetail(
    title: NSLocalizedString("Google's Event Community Guidelines and Anti-Harassment Policy", comment: "Google's Event Community guidelines title. The official guideline is not provided in any other language, so title translations do not need to be consistent."),
    detail: NSLocalizedString(
      """
      <p>
      Google is dedicated to providing a harassment-free and inclusive event experience for everyone regardless of gender identity and expression, sexual orientation, disabilities, neurodiversity, physical appearance, body size, ethnicity, nationality, race, age, religion, or other protected category. In an effort to make the event as inclusive as possible, gender-neutral bathrooms will be offered throughout the venue.
      </p><br />
      <p>
      We don't tolerate harassment of event participants in any form.
      Google takes violations of our policy seriously and will respond appropriately. For more information on Google's Event Community Guidelines and Anti-Harassment Policy, please see <a href="https://www.google.com/events/policy/anti-harassmentpolicy.html">here</a>.
      </p><br />
      <p>
      All participants of Google events must abide by the following policy:
      </p>
      <p>
      <strong>Be excellent to each other</strong>. Treat everyone with respect. Participate while acknowledging that everyone deserves to be here&mdash;and each of us has the right to enjoy our experience without fear of harassment, discrimination, or condescension, whether blatant or via micro-aggressions. Jokes shouldn't demean others. Consider what you are saying and how it would feel if it were said to or about you.
      </p><br />
      <p>
      <strong>Speak up if you see or hear something.</strong> Harassment is not tolerated, and you are empowered to politely engage when you or others are disrespected. The person making you feel uncomfortable may not be aware of what they are doing, and politely bringing their behavior to their attention is encouraged.
      </p>
      <p>
      <strong>Practice saying "Yes and" to each other.</strong> It's a theatre improv technique to build on each other's ideas. We all benefit when we create together.
      </p><br />
      <p>
      We have a <strong>ZERO TOLERANCE POLICY</strong> for harassment of any kind, including but not limited to:
      <ul>
        <li>Stalking/following</li>
        <li>Deliberate intimidation</li>
        <li>Harassing photography or recording</li>
        <li>Sustained disruption of talks or other events</li>
        <li>Offensive verbal language</li>
        <li>Verbal language that reinforces social structures of domination</li>
        <li>Sexual imagery and language in public spaces</li>
        <li>Inappropriate physical contact</li>
        <li>Unwelcome sexual or physical attention</li>
      </ul>
      <strong>In relation to, but not limited to:</strong>
      <ul>
        <li>Neurodiversity</li>
        <li>Race</li>
        <li>Color</li>
        <li>National origin</li>
        <li>Gender identity</li>
        <li>Gender expression</li>
        <li>Sexual orientation</li>
        <li>Age</li>
        <li>Body size</li>
        <li>Disabilities</li>
        <li>Appearance</li>
        <li>Religion</li>
        <li>Pregnancy</li>
      </ul>
      Participants asked to stop any harassing behavior are expected to comply immediately. Our zero-tolerance policy means that we'll look into and review every alleged violation of our Event Community Guidelines and Anti-Harassment Policy and respond appropriately. We empower and encourage you to report any behavior that makes you or others feel uncomfortable by finding a Google staff member or by emailing <a href="mailto:googleiocommunity@google.com">googleiocommunity@google.com</a>.
      </p><br />
      <p>
      Event staff will be happy to help participants contact hotel/venue security or local law enforcement, provide escorts, or otherwise assist those experiencing discomfort or harassment to feel safe for the duration of the event. We value your attendance.
      </p><br />
      <p>
      This policy extends to Sessions, forums, workshops, Codelabs, social media, parties, hallway conversations, all attendees, partners, sponsors, volunteers, event staff, etc. You catch our drift. Google reserves the right to refuse admittance to, or remove any person from, any Google-hosted event (including future Google events) at any time in its sole discretion. This includes, but is not limited to, attendees behaving in a disorderly manner or failing to comply with this policy, and the terms and conditions herein. If a participant engages in harassing or uncomfortable behavior, the conference organizers may take any action they deem appropriate, including a warning or expelling the offender from the conference with no refund.
      </p>
      """, comment: "Short description and link to the official I/O website, where the full FAQ text is available")
  )

  public static let liveStreamAndRecordings = InfoDetail(
    title: NSLocalizedString("Will the Sessions be livestreamed?  What if I can't follow the event in real time?", comment: "Livestream and Recordings title"),
    detail: NSLocalizedString("<p>The two Keynotes and all Sessions will be livestreamed on the event website's homepage during the three days of the festival. If you're busy at work or on the other side of the planet with a tricky time difference, you can watch the session recordings later on the <a href=\"https://www.youtube.com/user/GoogleDevelopers\">Google Developers YouTube channel</a>.</p>", comment: "Localized HTML describing video options for remote attendees")
  )

  public static let ioExtended = InfoDetail(
    title: NSLocalizedString("I want to celebrate I/O with my community! Any ideas?", comment: "Question about remote Google I/O attendance opportunities"),
    detail: NSLocalizedString(
      """
      <p>
      Yes! Every year, developers around the world host <a href="https://events.google.com/io/extended">Google I/O Extended</a> events. During these events, organizers can livestream the event and host their own sessions including hackathons, codelabs, demos, and more.
      If you're joining us as an I/O Extended host this year, here are the steps you should take to get started:
      <ul>
        <li>Read through the <a href="https://docs.google.com/presentation/d/e/2PACX-1vReWDtj-yASOho5q7XC6lYY8af9wRa13-81mPaoSRodiRoCw4MKJnQExQ8GxyNyCQiPZpBprznPG4ex/pub?slide=id.g62811f3b0_18">Organizer Guide</a> to get tips and suggestions on how to host a successful event.</li>
        <li><a href="https://events.google.com/io/extended/form">Register</a> your public event on the I/O website for increased visibility.</li>
        <li>Use the official #io19extended hashtag on all your social posts related to I/O Extended for easier discoverability.</li>
      </ul>
      Note: I/O Extended hosts can request the deletion of their personal and/or event data after the event ends by emailing <a href="mailto:io19@google.com">io19@google.com</a>.
      If you simply want to attend an I/O Extended event, browse our map to find one near you and RSVP!
      For questions about the I/O Extended program, contact us at <a href="mailto:io19extended-external@google.com">io19extended-external@google.com</a>.
      </p>
      """, comment: "Description of I/O extended viewing parties and how to host them")
  )

  public static let embedWidget = InfoDetail(
    title: NSLocalizedString("Can I embed the I/O livestream on my site?", comment: "Question asking if users are allowed to embed the I/O livestream on their personal websites"),
    detail: NSLocalizedString("Yes. The I/O Live widget allows you to deliver the I/O livestream and/or official #io19 social feed directly to your audience. We'll share more details on how to embed the I/O Live widget on your website soon.", comment: "A confirmation to a question asking if users can embed a livestream player in their websites.")
  )

  public static let faqDetails: [InfoDetail] = [
    .datesAndLocation,
    .stayInformed,
    .language,
    .reservations,
    .travel,
    .badgePickup,
    .keynoteSeating,
    .dressCode,
    .foodOptions,
    .lostAndFound,
    .afterDark,
    .accessibility,
    .mothers,
    .antiHarassmentPolicy,
    .liveStreamAndRecordings,
    .ioExtended,
    .embedWidget
  ]

  public static let allInfoDetails: [InfoDetail] = {
    return InfoDetail.faqDetails + InfoDetail.travelDetails
  }()

}

extension InfoDetail: Equatable {}
public func == (lhs: InfoDetail, rhs: InfoDetail) -> Bool {
  return lhs.title == rhs.title && lhs.detail == rhs.detail
}

// MARK: - Settings

final class SettingsViewModel {

  private let userState: PersistentUserState
  private let notificationPermissions: NotificationPermissions

  // The viewmodel does not guarantee its view controller is alive when
  // it needs to present things.
  weak var presentingViewController: UIViewController?

  init(userState: PersistentUserState, presentingViewController: UIViewController? = nil) {
    self.userState = userState
    self.notificationPermissions = NotificationPermissions(userState: userState,
                                                           application: .shared)
    self.presentingViewController = presentingViewController
  }

  var shouldDisplayEventsInPDT: Bool {
    get {
      return userState.shouldDisplayEventsInPDT
    }
    set {
      userState.setShouldDisplayEventsInPDT(newValue)
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
      if let appSettings = URL(string: UIApplication.openSettingsURLString) {
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
    shouldDisplayEventsInPDT = !shouldDisplayEventsInPDT
  }

  func toggleNotificationsEnabled() {
    isNotificationsEnabled = !isNotificationsEnabled
  }

  func toggleAnalyticsEnabled() {
    isAnalyticsEnabled = !isAnalyticsEnabled
  }

}
