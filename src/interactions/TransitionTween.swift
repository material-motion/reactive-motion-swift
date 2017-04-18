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

/**
 A transition tween animates a property between two states of a transition using a Tween.

 A transition tween can be associated with many properties. Each property receives its own distinct
 animator.

 **Constraints**

 T-value constraints may be applied to this interaction.
 */
public final class TransitionTween<T>: Tween<T> {

  /**
   The values to use when the transition is moving backward.
   */
  public let backwardValues: [T]

  /**
   The values to use when the transition is moving forward.
   */
  public let forwardValues: [T]

  /**
   The key positions to use when the transition is moving backward.
   */
  public let backwardKeyPositions: [CGFloat]

  /**
   The key positions to use when the transition is moving forward.
   */
  public let forwardKeyPositions: [CGFloat]

  /**
   Creates a transition tween.

   - parameter system: Often coreAnimation. Can be another system if a system support library is available.
   */
  public init(duration: CGFloat,
              forwardValues: [T],
              direction: ReactiveProperty<TransitionDirection>,
              forwardKeyPositions: [CGFloat] = [],
              system: @escaping TweenToStream<T> = coreAnimation,
              timeline: Timeline? = nil) {
    self.forwardValues = forwardValues
    self.backwardValues = forwardValues.reversed()
    self.forwardKeyPositions = forwardKeyPositions
    self.backwardKeyPositions = forwardKeyPositions.reversed().map { 1 - $0 }
    let values = direction == .forward ? forwardValues : backwardValues

    self.direction = direction

    self.toggledValues = direction.rewrite([.backward: backwardValues, .forward: forwardValues])
    self.toggledKeyPositions = direction.rewrite([.backward: backwardKeyPositions, .forward: forwardKeyPositions])
    super.init(duration: duration, values: values, system: system, timeline: timeline)
  }

  /**
   Creates a transition tween.
   
   - parameter system: Often coreAnimation. Can be another system if a system support library is available.
   */
  convenience public init(duration: DispatchTimeInterval,
              forwardValues: [T],
              direction: ReactiveProperty<TransitionDirection>,
              forwardKeyPositions: [CGFloat] = [],
              system: @escaping TweenToStream<T> = coreAnimation,
              timeline: Timeline? = nil) {
    let durationInSeconds = duration.toSeconds()
    self.init(duration: durationInSeconds, forwardValues: forwardValues, direction: direction, forwardKeyPositions: forwardKeyPositions, system: system, timeline: timeline)
  }
  
  public override func add(to property: ReactiveProperty<T>,
                           withRuntime runtime: MotionRuntime,
                           constraints: ConstraintApplicator<T>? = nil) {
    let unlocked = createProperty("TransitionTween.unlocked", withInitialValue: false)
    runtime.connect(direction.rewriteTo(false), to: unlocked)
    runtime.connect(toggledValues, to: values)
    runtime.connect(toggledKeyPositions, to: keyPositions)
    super.add(to: property, withRuntime: runtime) {
      var stream = $0
      if let constraints = constraints {
        stream = constraints($0)
      }
      return stream.valve(openWhenTrue: unlocked)
    }
    runtime.connect(direction.rewriteTo(true), to: unlocked)
  }

  private let direction: ReactiveProperty<TransitionDirection>
  private let toggledValues: MotionObservable<[T]>
  private let toggledKeyPositions: MotionObservable<[CGFloat]>
}
