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
import UIKit
import IndefiniteObservable

/** Create a core animation tween system for a Tween plan. */
public func coreAnimation<T>(_ tween: TweenShadow<T>) -> MotionObservable<T> {
  return streamFromTween(tween) { $0 }
}

/** Create an additive core animation tween system for a Tween plan. */
public func coreAnimation<T>(_ tween: TweenShadow<T>) -> MotionObservable<T> where T: Subtractable {
  return streamFromTween(tween) {
    var event = $0
    event.makeAdditive = { from, to in
      return (from as! T) - (to as! T)
    }
    return event
  }
}

private func streamFromTween<T>(_ tween: TweenShadow<T>, configureEvent: @escaping (CoreAnimationChannelAdd) -> CoreAnimationChannelAdd) -> MotionObservable<T> {
  return MotionObservable { observer in

    var animationKeys: [String] = []
    var activeAnimations = Set<String>()
    var lastValues: [T]?
    var lastOffsets: [CGFloat]?

    let checkAndEmit = {
      guard let values = lastValues, let offsets = lastOffsets, tween.enabled.value else {
        return
      }
      let animation: CAPropertyAnimation
      let timingFunctions = tween.timingFunctions
      if values.count > 1 {
        let keyframeAnimation = CAKeyframeAnimation()
        keyframeAnimation.values = values
        keyframeAnimation.keyTimes = offsets.map { NSNumber(value: Double($0)) }
        keyframeAnimation.timingFunctions = timingFunctions.value
        animation = keyframeAnimation
      } else {
        let basicAnimation = CABasicAnimation()
        basicAnimation.toValue = values.last
        basicAnimation.timingFunction = timingFunctions.value.first
        animation = basicAnimation
      }
      observer.next(values.last!)

      guard let duration = tween.duration._read() else {
        return
      }
      animation.beginTime = CFTimeInterval(tween.delay.value)
      if tween.delay.value > 0 {
        animation.fillMode = CAMediaTimingFillMode.backwards
      }
      animation.duration = CFTimeInterval(duration)
      animation.repeatCount = Float(tween.repeatCount.value)
      animation.repeatDuration = CFTimeInterval(tween.repeatDuration.value)
      animation.autoreverses = tween.autoreverses.value

      let key = NSUUID().uuidString
      activeAnimations.insert(key)
      animationKeys.append(key)

      tween.state.value = .active

      var info = CoreAnimationChannelAdd(animation: animation, key: key, onCompletion: {
        activeAnimations.remove(key)
        if activeAnimations.count == 0 {
          tween.state.value = .atRest
        }
      })
      info = configureEvent(info)
      info.timeline = tween.timeline
      observer.coreAnimation?(.add(info))
      animationKeys.append(key)
    }

    // To avoid excessive animation re-emissions, we subscribe to active before any of the
    // configuration stream subscriptions so that checkAndEmit will bail out early.
    let activeSubscription = tween.enabled.dedupe().subscribeToValue { enabled in
      if enabled {
        checkAndEmit()

      } else {
        animationKeys.forEach { observer.coreAnimation?(.remove($0)) }
        activeAnimations.removeAll()
        animationKeys.removeAll()
        tween.state.value = .atRest
      }
    }

    let valuesSubscription = tween.values.subscribeToValue { values in
      lastValues = values
      checkAndEmit()
    }

    let offsetsSubscription = tween.offsets.subscribeToValue { offsets in
      lastOffsets = offsets
      checkAndEmit()
    }

    return {
      animationKeys.forEach { observer.coreAnimation?(.remove($0)) }
      animationKeys.removeAll()
      activeAnimations.removeAll()

      lastValues = nil
      lastOffsets = nil
      activeSubscription.unsubscribe()
      valuesSubscription.unsubscribe()
      offsetsSubscription.unsubscribe()
    }
  }
}
