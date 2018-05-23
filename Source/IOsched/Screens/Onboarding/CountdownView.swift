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

import Lottie
import UIKit

class CountdownView: UIView {

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError("NSCoding not supported")
  }

  public init() {
    super.init(frame: CGRect(x: 0, y: 0, width: 260, height: 240))

    addSubview(secondsOnesDigit)
    addSubview(secondsTensDigit)
    addSubview(minutesOnesDigit)
    addSubview(minutesTensDigit)
    addSubview(hoursOnesDigit)
    addSubview(hoursTensDigit)
    addSubview(daysOnesDigit)
    addSubview(daysTensDigit)

    addSubview(secondsLabel)
    addSubview(minutesLabel)
    addSubview(hoursLabel)
    addSubview(daysLabel)

    addConstraints(digitConstraints)
    addConstraints(labelConstraints)

    isUserInteractionEnabled = true

    setupInitialState()

    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  convenience override init(frame: CGRect) {
    self.init()
  }

  static var contentSize: CGSize {
    if IODateComparer.currentDateRelativeToIO() != .before {
      return .zero
    } else {
      return CGSize(width: 260, height: 240)
    }
  }

  override var intrinsicContentSize: CGSize {
    return CountdownView.contentSize
  }

  private lazy var targetDate: Date = {
    return IODateComparer.ioStartDate
  }()

  func timeLeftUntilTargetDate(from date: Date = Date()) -> TimeInterval {
    let difference = targetDate.timeIntervalSince(date)
    return difference > 0 ? difference : 0
  }

  func setupInitialState() {
    for view in allAnimationViews {
      if let animationView = view as? AnimationView {
        animationView.stop()
      }
    }
    let timeRemaining = timeLeftUntilTargetDate()
    setTimeRemaining(timeRemaining)

    var progress = progressInterval(from: secondsOnes, to: 0)
    secondsOnesDigit.currentProgress = progress.0
    progress = progressInterval(from: secondsTens, to: 0)
    secondsTensDigit.currentProgress = progress.0
    progress = progressInterval(from: minutesOnes, to: 0)
    minutesOnesDigit.currentProgress = progress.0
    progress = progressInterval(from: minutesTens, to: 0)
    minutesTensDigit.currentProgress = progress.0
    progress = progressInterval(from: hoursOnes, to: 0)
    hoursOnesDigit.currentProgress = progress.0
    progress = progressInterval(from: hoursTens, to: 0)
    hoursTensDigit.currentProgress = progress.0
    progress = progressInterval(from: daysOnes, to: 0)
    daysOnesDigit.currentProgress = progress.0
    progress = progressInterval(from: daysTens, to: 0)
    daysTensDigit.currentProgress = progress.0
  }

  // MARK: - Number animation views

  private func animationView() -> AnimationView {
    let view = AnimationView()
    view.animation = nil
    view.translatesAutoresizingMaskIntoConstraints = false
    view.contentMode = .scaleAspectFit
    view.animation = CountdownView.animation
    view.loopMode = .playOnce
    view.backgroundBehavior = .stop
    return view
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    // Multi-touch is not enabled by default, so touches should only have one object.
    if let touch = touches.first, bounds.contains(touch.location(in: self)) {
      viewTapped(self)
    }
  }

  private static let animation = Animation.named("countdown9-0")

  private func newTimer() -> Timer {
    let timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(updateWithAnimations(_:)),
                                     userInfo: nil,
                                     repeats: true)
    timer.tolerance = 0.1
    return timer
  }

  private var timer: Timer? {
    didSet {
      oldValue?.invalidate()
    }
  }

  var paused: Bool {
    return timer == nil
  }

  func play() {
    timer = newTimer()
  }

  func stop() {
    timer = nil
  }

  @objc private func viewTapped(_ sender: Any) {
    if paused {
      play()
    } else {
      stop()
    }
  }

  @objc private func updateWithAnimations(_ sender: Any) {
    let timeRemaining = timeLeftUntilTargetDate()
    setTimeRemaining(timeRemaining)

    if timeRemaining == 0 {
      collapse()
    }
  }

  private var isCollapsed: Bool = false

  private func collapse() {
    stop()
    for view in subviews {
      view.removeFromSuperview()
    }
    isCollapsed = true
  }

  private func setTimeRemaining(_ timeRemaining: TimeInterval) {
    let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
    let secondsOnes = seconds % 10
    let secondsTens = (seconds - secondsOnes) / 10

    let minutes = Int(timeRemaining / 60) % 60
    let minutesOnes = minutes % 10
    let minutesTens = (minutes - minutesOnes) / 10

    let hours = Int(timeRemaining / 3600) % 24
    let hoursOnes = hours % 10
    let hoursTens = (hours - hoursOnes) / 10

    let days = Int(timeRemaining / 86400) // disregard leap seconds, acquire bugs
    let daysOnes = days % 10
    let daysTens = (days % 100 - daysOnes) / 10

    self.secondsOnes = secondsOnes
    self.secondsTens = secondsTens
    self.minutesOnes = minutesOnes
    self.minutesTens = minutesTens
    self.hoursOnes = hoursOnes
    self.hoursTens = hoursTens
    self.daysOnes = daysOnes
    self.daysTens = daysTens
  }

  private func progressInterval(from oldValue: Int, to newValue: Int) -> (CGFloat, CGFloat) {
    let startingProgress = (CGFloat(10 - oldValue) / 10).truncatingRemainder(dividingBy: 1)
    let endingProgress = CGFloat(10 - newValue) / 10
    return (startingProgress, endingProgress)
  }

  private func animateView(_ view: AnimationView,
                           oldValue: Int,
                           newValue: Int) {
    if oldValue == newValue { return }
    // Special case for animating from 0 -> 6 for seconds' tens place digit.
    if oldValue == 0 && newValue != 9 {
      let animateOutProgressInterval: (CGFloat, CGFloat) = (0, 0.05)
      let animateInStart = CGFloat(10 - newValue) / 10 - 0.05
      let animateInEnd = animateInStart + 0.05
      view.play(fromProgress: animateOutProgressInterval.0,
                toProgress: animateOutProgressInterval.1,
                completion: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        view.play(fromProgress: animateInStart, toProgress: animateInEnd, completion: nil)
      }
    } else {
      let progress = progressInterval(from: oldValue, to: newValue)
      view.play(fromProgress: progress.0, toProgress: progress.1, completion: nil)
    }
  }

  private var secondsOnes: Int = 10 {
    didSet {
      animateView(secondsOnesDigit,
                  oldValue: oldValue,
                  newValue: secondsOnes)
    }
  }
  private var secondsTens: Int = 10 {
    didSet {
      animateView(secondsTensDigit,
                  oldValue: oldValue,
                  newValue: secondsTens)
    }
  }
  private var minutesOnes: Int = 10 {
    didSet {
      animateView(minutesOnesDigit,
                  oldValue: oldValue,
                  newValue: minutesOnes)
    }
  }
  private var minutesTens: Int = 10 {
    didSet {
      animateView(minutesTensDigit,
                  oldValue: oldValue,
                  newValue: minutesTens)
    }
  }
  private var hoursOnes: Int = 10 {
    didSet {
      animateView(hoursOnesDigit,
                  oldValue: oldValue,
                  newValue: hoursOnes)
    }
  }
  private var hoursTens: Int = 10 {
    didSet {
      animateView(hoursTensDigit,
                  oldValue: oldValue,
                  newValue: hoursTens)
    }
  }
  private var daysOnes: Int = 10 {
    didSet {
      animateView(daysOnesDigit,
                  oldValue: oldValue,
                  newValue: daysOnes)
    }
  }
  private var daysTens: Int = 10 {
    didSet {
      animateView(daysTensDigit,
                  oldValue: oldValue,
                  newValue: daysTens)
    }
  }

  private lazy var secondsOnesDigit = animationView()
  private lazy var secondsTensDigit = animationView()
  private lazy var minutesOnesDigit = animationView()
  private lazy var minutesTensDigit = animationView()
  private lazy var hoursOnesDigit = animationView()
  private lazy var hoursTensDigit = animationView()
  private lazy var daysOnesDigit = animationView()
  private lazy var daysTensDigit = animationView()

  private lazy var allAnimationViews: [UIView] = {
    return [
      secondsOnesDigit,
      secondsTensDigit,
      minutesOnesDigit,
      minutesTensDigit,
      hoursOnesDigit,
      hoursTensDigit,
      daysOnesDigit,
      daysTensDigit,
      secondsLabel,
      minutesLabel,
      hoursLabel,
      daysLabel
    ]
  }()

  // Strings passed to this function should be localized.
  private func digitsLabel(withText text: String) -> UILabel {
    let label = UILabel()
    label.isAccessibilityElement = false
    label.textColor = UIColor(hex: "#747474")
    label.text = text
    label.font = UIFont.systemFont(ofSize: 11)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }

  lazy private var secondsLabel =
      digitsLabel(withText: NSLocalizedString("S",
                                              comment: "Abbreviation for seconds, capitalized where applicable"))
  lazy private var minutesLabel =
      digitsLabel(withText: NSLocalizedString("M",
                                              comment: "Abbreviation for minutes, capitalized where applicable"))
  lazy private var hoursLabel =
      digitsLabel(withText: NSLocalizedString("H",
                                              comment: "Abbreviation for hours, capitalized where applicable"))
  lazy private var daysLabel =
      digitsLabel(withText: NSLocalizedString("D",
                                              comment: "Abbreviation for days, capitalized where applicable"))

  // MARK: - Autolayout constraints

  private var digitConstraints: [NSLayoutConstraint] {
    let verticalSpacing: CGFloat = 22.5
    let horizontalSpacing: CGFloat = 20
    return [
      // seconds ones digit
      NSLayoutConstraint(item: secondsOnesDigit, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: secondsOnesDigit, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing + 60),
      NSLayoutConstraint(item: secondsOnesDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: secondsOnesDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),

      // seconds tens digit
      NSLayoutConstraint(item: secondsTensDigit, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: secondsTensDigit, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing),
      NSLayoutConstraint(item: secondsTensDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: secondsTensDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),

      // minutes ones digit
      NSLayoutConstraint(item: minutesOnesDigit, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: minutesOnesDigit, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing),
      NSLayoutConstraint(item: minutesOnesDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: minutesOnesDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),

      // minutes tens digit
      NSLayoutConstraint(item: minutesTensDigit, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: minutesTensDigit, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing - 60),
      NSLayoutConstraint(item: minutesTensDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: minutesTensDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),

      // hours ones digit
      NSLayoutConstraint(item: hoursOnesDigit, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: hoursOnesDigit, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing + 60),
      NSLayoutConstraint(item: hoursOnesDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: hoursOnesDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),

      // hours tens digit
      NSLayoutConstraint(item: hoursTensDigit, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: hoursTensDigit, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing),
      NSLayoutConstraint(item: hoursTensDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: hoursTensDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),

      // days ones digit
      NSLayoutConstraint(item: daysOnesDigit, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: daysOnesDigit, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing),
      NSLayoutConstraint(item: daysOnesDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: daysOnesDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),

      // days tens digit
      NSLayoutConstraint(item: daysTensDigit, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: daysTensDigit, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing - 60),
      NSLayoutConstraint(item: daysTensDigit, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: daysTensDigit, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80)
    ]
  }

  private var labelConstraints: [NSLayoutConstraint] {
    return [
      // seconds
      NSLayoutConstraint(item: secondsLabel, attribute: .left,
                         relatedBy: .equal,
                         toItem: secondsTensDigit, attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: secondsLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: secondsTensDigit, attribute: .bottom,
                         multiplier: 1,
                         constant: 2),

      // minutes
      NSLayoutConstraint(item: minutesLabel, attribute: .left,
                         relatedBy: .equal,
                         toItem: minutesTensDigit, attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: minutesLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: minutesTensDigit, attribute: .bottom,
                         multiplier: 1,
                         constant: 2),

      // hours
      NSLayoutConstraint(item: hoursLabel, attribute: .left,
                         relatedBy: .equal,
                         toItem: hoursTensDigit, attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: hoursLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: hoursTensDigit, attribute: .bottom,
                         multiplier: 1,
                         constant: 2),

      // days
      NSLayoutConstraint(item: daysLabel, attribute: .left,
                         relatedBy: .equal,
                         toItem: daysTensDigit, attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: daysLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: daysTensDigit, attribute: .bottom,
                         multiplier: 1,
                         constant: 2)
    ]
  }

  // MARK: - Accessibility

  private static let dateComponentsFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour, .minute, .second]
    formatter.allowsFractionalUnits = false
    formatter.includesTimeRemainingPhrase = true
    formatter.unitsStyle = .full
    return formatter
  }()

  override var isAccessibilityElement: Bool {
    get {
      return true
    } set {}
  }

  override var accessibilityLabel: String? {
    get {
      return NSLocalizedString("I/O 2019 countdown.",
                               comment: "Localized accessibility label for the I/O countdown animation")
    } set {}
  }

  override var accessibilityValue: String? {
    get {
      let timeInterval = timeLeftUntilTargetDate()
      let timeRemainingString =
          CountdownView.dateComponentsFormatter.string(from: timeInterval)
      return timeRemainingString
    } set {}
  }

  override var accessibilityTraits: UIAccessibilityTraits {
    get {
      return UIAccessibilityTraits.updatesFrequently
    } set {}
  }

  override func accessibilityActivate() -> Bool {
    return false
  }

}
