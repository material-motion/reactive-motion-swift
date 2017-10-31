/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import CoreGraphics

extension DispatchTimeInterval {
  func toSeconds() -> CGFloat {
    let seconds: CGFloat

    // `.never` was introduced in the latest SDK. In order to support both Xcode 8 and 9 we have to
    // implement the `case .never` while not implementing it on Xcode 8. Unfortunately, `#if swift`
    // statements placed inside of switch statements can't build, so we're stuck duplicating the
    // switch statement.
    //
    // If we try to write the code like so:
    //
    //     #if swift(>=3.2)
    //       case .never:
    //       seconds = CGFloat.infinity
    //     #endif
    //
    // We get the following errors:
    //
    //     Extraneous '.' in enum 'case' declaration
    //     'case' label can only appear inside a 'switch' statement

#if swift(>=3.2)
    switch self {
    case let .seconds(arg):
      seconds = CGFloat(arg)
    case let .milliseconds(arg):
      seconds = CGFloat(arg) / 1000.0
    case let .microseconds(arg):
      seconds = CGFloat(arg) / 1000000.0
    case let .nanoseconds(arg):
      seconds = CGFloat(arg) / 1000000000.0
    case .never:
      seconds = CGFloat.infinity
    }
#else
    switch self {
    case let .seconds(arg):
      seconds = CGFloat(arg)
    case let .milliseconds(arg):
      seconds = CGFloat(arg) / 1000.0
    case let .microseconds(arg):
      seconds = CGFloat(arg) / 1000000.0
    case let .nanoseconds(arg):
      seconds = CGFloat(arg) / 1000000000.0
    }
#endif
    return seconds
  }
}
