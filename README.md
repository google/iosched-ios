# Google I/O iOS App

Google I/O is a developer conference held each year with two days of deep
technical content featuring technical sessions and hundreds of demonstrations
from developers showcasing their technologies.

This project is the iOS app for the conference.

## Building

You'll need a Firebase project to run IOsched. Copy your project's
`GoogleService-Info.plist` file into the `Source/IOsched/Configuration`
directory. For instructions on how to create an iOS app in your Firebase
project, see the "Add Firebase to your app" section of
[this document](https://firebase.google.com/docs/ios/setup).

CocoaPods 1.4.0 and Xcode 9.2 or higher are required.

Run `pod install` in the `Source` directory, open `IOsched.xcworkspace`, and
build and run the IOsched target.

Note that the backend is dependent on Cloud Functions and Firestore, so
when running the app you may not see any data if your project's Firestore
data store is empty. Similarly, backend functions like reservations
and stars won't function.

## License

    Copyright 2017 Google Inc. All rights reserved.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
