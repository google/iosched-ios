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
import Platform

class CountdownView: UIView {

  private lazy var rabbitHoleImageView: UIImageView = self.setupRabbitHoleImageView()

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

    addSubview(secondsOnesDigitBackground)
    addSubview(secondsTensDigitBackground)
    addSubview(minutesOnesDigitBackground)
    addSubview(minutesTensDigitBackground)
    addSubview(hoursOnesDigitBackground)
    addSubview(hoursTensDigitBackground)
    addSubview(daysOnesDigitBackground)
    addSubview(daysTensDigitBackground)

    addSubview(secondsLabel)
    addSubview(minutesLabel)
    addSubview(hoursLabel)
    addSubview(daysLabel)

    addSubview(rabbitHoleImageView)
    rabbitHoleImageView.isHidden = true

    addConstraints(digitConstraints)
    addConstraints(labelConstraints)
    addConstraints(imageViewConstraints)
  }

  convenience override init(frame: CGRect) {
    self.init()
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 260, height: 240)
  }

  lazy var targetDate: Date = {
    let dateComponents = DateComponents(calendar: Calendar.current,
                                        timeZone: TimeUtils.pacificTimeZone,
                                        era: nil,
                                        year: 2018,
                                        month: 5,
                                        day: 8,
                                        hour: 10,
                                        minute: 0,
                                        second: 0,
                                        nanosecond: 0,
                                        weekday: nil,
                                        weekdayOrdinal: nil,
                                        quarter: nil,
                                        weekOfMonth: nil,
                                        weekOfYear: nil,
                                        yearForWeekOfYear: nil)
    return dateComponents.date!
  }()

  func timeLeftUntilTargetDate(from date: Date = Date()) -> TimeInterval {
    let difference = targetDate.timeIntervalSince(date)
    return difference > 0 ? difference : 0
  }

  // MARK: - Number animation views

  private func randomRabbitHoleImage() -> UIImage? {
    let randomNumber = arc4random_uniform(20) + 1
    let randomImageName = "tree\(randomNumber)"
    return UIImage(named: randomImageName)
  }

  private func setupRabbitHoleImageView() -> UIImageView {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = randomRabbitHoleImage()
    return imageView
  }

  private func animationView() -> LOTAnimationView {
    let view = LOTAnimationView()
    view.setAnimation(named: animationName(forDigit: 0))
    view.translatesAutoresizingMaskIntoConstraints = false
    view.contentMode = .scaleAspectFit
    return view
  }

  private func animationName(forDigit digit: Int) -> String {
    switch digit {
    case 0 ..< 10:
      return String(describing: digit)

    case _:
      return animationName(forDigit: 0)
    }
  }

  private func newTimer() -> Timer {
    let timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(updateWithAnimations(_:)),
                                     userInfo: nil,
                                     repeats: true)
    return timer
  }

  private var timer: Timer? {
    willSet {
      stop()
    }
  }

  func play() {
    timer = newTimer()
  }

  func stop() {
    timer?.invalidate()
  }

  private func showRabbitHoleImageView() {
    timer = nil

    rabbitHoleImageView.alpha = 0
    rabbitHoleImageView.isHidden = false
    UIView.animate(withDuration: 0.5, animations: {
      self.allAnimationViews.forEach { $0.alpha = 0 }
    }) { _ in
      self.allAnimationViews.forEach { $0.isHidden = true }
      UIView.animate(withDuration: 0.5) {
        self.rabbitHoleImageView.alpha = 1
      }
    }
  }

  @objc private func updateWithAnimations(_ sender: Any) {
    let timeRemaining = timeLeftUntilTargetDate()
    setTimeRemaining(timeRemaining)

    if timeRemaining == 0 {
      showRabbitHoleImageView()
    }
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

  private func animateView(_ view: LOTAnimationView,
                           backgroundView: LOTAnimationView,
                           oldValue: Int,
                           newValue: Int) {
    if newValue != oldValue {
      backgroundView.setAnimation(named: animationName(forDigit: oldValue))
      backgroundView.play(fromProgress: 0.5, toProgress: 1.0, withCompletion: nil)
      // Start the new animation on the next-ish run loop iteration to prevent flickering.
      DispatchQueue.main
          .asyncAfter(deadline: .now() + 0.1) {
            view.setAnimation(named: self.animationName(forDigit: newValue))
            view.play(fromProgress: 0, toProgress: 0.5, withCompletion: nil)
      }
    }
  }

  private var secondsOnes: Int = 10 {
    didSet {
      animateView(secondsOnesDigit,
                  backgroundView: secondsOnesDigitBackground,
                  oldValue: oldValue,
                  newValue: secondsOnes)
    }
  }
  private var secondsTens: Int = 10 {
    didSet {
      animateView(secondsTensDigit,
                  backgroundView: secondsTensDigitBackground,
                  oldValue: oldValue,
                  newValue: secondsTens)
    }
  }
  private var minutesOnes: Int = 10 {
    didSet {
      animateView(minutesOnesDigit,
                  backgroundView: minutesOnesDigitBackground,
                  oldValue: oldValue,
                  newValue: minutesOnes)
    }
  }
  private var minutesTens: Int = 10 {
    didSet {
      animateView(minutesTensDigit,
                  backgroundView: minutesTensDigitBackground,
                  oldValue: oldValue,
                  newValue: minutesTens)
    }
  }
  private var hoursOnes: Int = 10 {
    didSet {
      animateView(hoursOnesDigit,
                  backgroundView: hoursOnesDigitBackground,
                  oldValue: oldValue,
                  newValue: hoursOnes)
    }
  }
  private var hoursTens: Int = 10 {
    didSet {
      animateView(hoursTensDigit,
                  backgroundView: hoursTensDigitBackground,
                  oldValue: oldValue,
                  newValue: hoursTens)
    }
  }
  private var daysOnes: Int = 10 {
    didSet {
      animateView(daysOnesDigit,
                  backgroundView: daysOnesDigitBackground,
                  oldValue: oldValue,
                  newValue: daysOnes)
    }
  }
  private var daysTens: Int = 10 {
    didSet {
      animateView(daysTensDigit,
                  backgroundView: daysTensDigitBackground,
                  oldValue: oldValue,
                  newValue: daysTens)
    }
  }

  private lazy var secondsOnesDigit = animationView()
  private lazy var secondsOnesDigitBackground = animationView()
  private lazy var secondsTensDigit = animationView()
  private lazy var secondsTensDigitBackground = animationView()
  private lazy var minutesOnesDigit = animationView()
  private lazy var minutesOnesDigitBackground = animationView()
  private lazy var minutesTensDigit = animationView()
  private lazy var minutesTensDigitBackground = animationView()
  private lazy var hoursOnesDigit = animationView()
  private lazy var hoursOnesDigitBackground = animationView()
  private lazy var hoursTensDigit = animationView()
  private lazy var hoursTensDigitBackground = animationView()
  private lazy var daysOnesDigit = animationView()
  private lazy var daysOnesDigitBackground = animationView()
  private lazy var daysTensDigit = animationView()
  private lazy var daysTensDigitBackground = animationView()

  private lazy var allAnimationViews: [UIView] = {
    return [
      secondsOnesDigit, secondsOnesDigitBackground,
      secondsTensDigit, secondsTensDigitBackground,
      minutesOnesDigit, minutesOnesDigitBackground,
      minutesTensDigit, minutesTensDigitBackground,
      hoursOnesDigit, hoursOnesDigitBackground,
      hoursTensDigit, hoursTensDigitBackground,
      daysOnesDigit, daysOnesDigitBackground,
      daysTensDigit, daysTensDigitBackground,
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
      NSLayoutConstraint(item: secondsOnesDigitBackground, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: secondsOnesDigitBackground, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing + 60),
      NSLayoutConstraint(item: secondsOnesDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: secondsOnesDigitBackground, attribute: .height,
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
      NSLayoutConstraint(item: secondsTensDigitBackground, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: secondsTensDigitBackground, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing),
      NSLayoutConstraint(item: secondsTensDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: secondsTensDigitBackground, attribute: .height,
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
      NSLayoutConstraint(item: minutesOnesDigitBackground, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: minutesOnesDigitBackground, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing),
      NSLayoutConstraint(item: minutesOnesDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: minutesOnesDigitBackground, attribute: .height,
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
      NSLayoutConstraint(item: minutesTensDigitBackground, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: verticalSpacing),
      NSLayoutConstraint(item: minutesTensDigitBackground, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing - 60),
      NSLayoutConstraint(item: minutesTensDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: minutesTensDigitBackground, attribute: .height,
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
      NSLayoutConstraint(item: hoursOnesDigitBackground, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: hoursOnesDigitBackground, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing + 60),
      NSLayoutConstraint(item: hoursOnesDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: hoursOnesDigitBackground, attribute: .height,
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
      NSLayoutConstraint(item: hoursTensDigitBackground, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: hoursTensDigitBackground, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: horizontalSpacing),
      NSLayoutConstraint(item: hoursTensDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: hoursTensDigitBackground, attribute: .height,
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
      NSLayoutConstraint(item: daysOnesDigitBackground, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: daysOnesDigitBackground, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing),
      NSLayoutConstraint(item: daysOnesDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: daysOnesDigitBackground, attribute: .height,
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
                         constant: 80),
      NSLayoutConstraint(item: daysTensDigitBackground, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: -verticalSpacing),
      NSLayoutConstraint(item: daysTensDigitBackground, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: -horizontalSpacing - 60),
      NSLayoutConstraint(item: daysTensDigitBackground, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 50),
      NSLayoutConstraint(item: daysTensDigitBackground, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 80),
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
                         constant: 2),
    ]
  }

  private var imageViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: rabbitHoleImageView, attribute: .centerX,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerX,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: rabbitHoleImageView, attribute: .centerY,
                         relatedBy: .equal,
                         toItem: self, attribute: .centerY,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: rabbitHoleImageView, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 260),
      NSLayoutConstraint(item: rabbitHoleImageView, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1,
                         constant: 240),
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
      if !rabbitHoleImageView.isHidden {
        return NSLocalizedString("Rabbit hole URL. Double-tap to see where it goes.",
                                 comment: "Localized accessibility label for rabbit hole puzzle")
      } else {
        return NSLocalizedString("I/O 2018 countdown.",
                                 comment: "Localized accessibility label for the I/O countdown animation")
      }
    } set {}
  }

  override var accessibilityValue: String? {
    get {
      if rabbitHoleImageView.isHidden {
        let timeInterval = timeLeftUntilTargetDate()
        let timeRemainingString =
            CountdownView.dateComponentsFormatter.string(from: timeInterval)
        return timeRemainingString
      } else {
        return nil
      }
    } set {}
  }

  override var accessibilityTraits: UIAccessibilityTraits {
    get {
      if rabbitHoleImageView.isHidden {
        return UIAccessibilityTraitUpdatesFrequently
      } else {
        return UIAccessibilityTraitLink
      }
    } set {}
  }

  override func accessibilityActivate() -> Bool {
    if rabbitHoleImageView.isHidden {
      return false
    } else {
      let url = URL(string: "https://www.find.foo/rtq3TnCh")!
      UIApplication.shared.openURL(url)
      return true
    }
  }

}
