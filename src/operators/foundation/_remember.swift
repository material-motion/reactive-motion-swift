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

import UIKit
import IndefiniteObservable

extension MotionObservableConvertible {

  /**
   Caches the most recent upstream value and broadcasts it to all subscribers.

   A memory stream will only subscribe to its upstream the first time a subscription is made.
   Upstream values will be synchronously emitted to all subscribers.

   When an observer subscribes it will synchronously receive the most recent upstream value, if any.
   */
  public func _remember() -> MotionObservable<T> {
    var observers: [MotionObserver<T>] = []
    var subscription: Subscription?

    var lastValue: T?
    var lastCoreAnimationEvent: CoreAnimationChannelEvent?
    var lastVisualizationView: UIView?

    return MotionObservable<T> { observer in
      if observers.count == 0 {
        subscription = self.subscribe(next: { value in
          lastValue = value
          for observer in observers {
            observer.next(value)
          }
        }, coreAnimation: { event in
          lastCoreAnimationEvent = event
          for observer in observers {
            observer.coreAnimation?(event)
          }
        }, visualization: { view in
          lastVisualizationView = view
          for observer in observers {
            observer.visualization?(view)
          }
        })
      }

      // Add the observer to the list after subscribing so that we don't double-send.
      observers.append(observer)

      if let lastValue = lastValue {
        observer.next(lastValue)
      }
      if let lastCoreAnimationEvent = lastCoreAnimationEvent {
        observer.coreAnimation?(lastCoreAnimationEvent)
      }
      if let lastVisualizationView = lastVisualizationView {
        observer.visualization?(lastVisualizationView)
      }

      return {
        if let index = observers.firstIndex(where: { $0 === observer }) {
          observers.remove(at: index)
          if observers.count == 0 {
            subscription?.unsubscribe()
            subscription = nil
          }
        }
      }
    }
  }
}
