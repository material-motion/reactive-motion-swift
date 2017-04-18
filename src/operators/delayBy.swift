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
import IndefiniteObservable

extension MotionObservableConvertible {

  /**
   Emits values from upstream after the specified delay.
   */
  public func delay(by duration: CGFloat) -> MotionObservable<T> {
    return MotionObservable(self.metadata.createChild(Metadata(#function, type: .constraint, args: [duration]))) { observer in
      var subscription: Subscription?

      subscription = self.asStream().subscribeAndForward(to: observer) { value in
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(Int(duration * 1000))) {
          guard subscription != nil else {
            return
          }
          observer.next(value)
        }
      }

      return {
        subscription?.unsubscribe()
        subscription = nil
      }
    }
  }

  /**
   Emits values from upstream after the specified delay.
   */
  public func delay(by duration: DispatchTimeInterval) -> MotionObservable<T> {
    let durationInSeconds = duration.toSeconds()
    return self.delay(by: durationInSeconds)
  }
}
