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
 A tween is an interpolation between two or more values, often making use of a non-linear timing
 function.

 **Constraints**

 T-value constraints may be applied to this interaction.
 */
public class Tween<T>: Interaction, Togglable, Stateful {

  /**
   The duration of the animation in seconds.
   */
  public let duration: ReactiveProperty<CGFloat>

  /**
   The number of times the animation will repeat.

   If the repeatCount is 0, it is ignored. If both repeatDuration and repeatCount are specified the behavior is undefined.

   Setting this property to greatestFiniteMagnitude will cause the animation to repeat forever.

   See https://developer.apple.com/reference/quartzcore/camediatiming/1427666-repeatcount for more information.
   */
  public let repeatCount: ReactiveProperty<CGFloat> = createProperty(withInitialValue: 0)

  /**
   The number of seconds the animation will repeat for.

   If the repeatDuration is 0, it is ignored. If both repeatDuration and repeatCount are specified the behavior is undefined.

   See https://developer.apple.com/reference/quartzcore/camediatiming/1427643-repeatduration for more information.
   */
  public let repeatDuration: ReactiveProperty<CGFloat> = createProperty(withInitialValue: 0)

  /**
   Will the animation play in the reverse upon completion.

   See https://developer.apple.com/reference/quartzcore/camediatiming/1427645-autoreverses for more information.
   */
  public let autoreverses: ReactiveProperty<Bool> = createProperty(withInitialValue: false)

  /**
   The delay of the animation in seconds.
   */
  public let delay = createProperty(withInitialValue: 0)

  /**
   An array of objects providing the value of the animation for each keyframe.

   If values.count == 1 then the sole value will be treated as the toValue in a basic animation.

   See CAKeyframeAnimation documentation for more details.
   */
  public let values: ReactiveProperty<[T]>

  /**
   An array of number values defining the pacing of the animation.

   Each position corresponds to one value in the `values' array, and defines when the value should
   be used in the animation function. Each value in the array is a floating point number in the
   range [0,1].

   See CAKeyframeAnimation documentation for more details.
   */
  public let offsets = createProperty(withInitialValue: [] as [CGFloat])

  /**
   An array of CAMediaTimingFunction objects. If the `values' array defines n keyframes,
   there should be n-1 objects in the `timingFunctions' array. Each function describes the pacing of
   one keyframe to keyframe segment.

   If values.count == 1 then a single timing function may be provided to configure the basic
   animation.

   See CAKeyframeAnimation documentation for more details.
   */
  public let timingFunctions = createProperty(withInitialValue:
    [CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)]
  )

  /**
   An optional timeline that may scrub this tween animation.

   If provided, this tween is expected to be timed in relation to the timeline's beginTime.
   */
  public let timeline: Timeline?

  /**
   Whether or not the tween animation is currently taking effect.

   Enabling a previously disabled tween will restart the animation from the beginning.
   */
  public let enabled = createProperty(withInitialValue: true)

  /**
   The current state of the tween animation.
   */
  public var state: MotionObservable<MotionState> {
    return _state.asStream()
  }

  /**
   Initializes a tween instance with its required properties.
   */
  public init(duration: CGFloat, values: [T], system: @escaping TweenToStream<T> = coreAnimation, timeline: Timeline? = nil) {
    self.duration = createProperty(withInitialValue: duration)
    self.values = createProperty(withInitialValue: values)
    self.system = system
    self.timeline = timeline
  }

  /**
   Initializes a tween instance with its required properties.
   */
  convenience public init(duration: DispatchTimeInterval, values: [T], system: @escaping TweenToStream<T> = coreAnimation, timeline: Timeline? = nil) {
    let durationInSeconds = duration.toSeconds()
    self.init(duration: durationInSeconds, values: values, system: system, timeline: timeline)
  }

  public func add(to property: ReactiveProperty<T>,
                  withRuntime runtime: MotionRuntime,
                  constraints applyConstraints: ConstraintApplicator<T>? = nil) {
    var stream = asStream()
    if let applyConstraints = applyConstraints {
      stream = applyConstraints(stream)
    }
    runtime.connect(stream, to: property)
  }

  private func asStream() -> MotionObservable<T> {
    if stream == nil {
      stream = system(TweenShadow(of: self))._remember()
    }
    return stream!
  }

  fileprivate let system: TweenToStream<T>
  fileprivate var stream: MotionObservable<T>?
  fileprivate let _state = createProperty(withInitialValue: MotionState.atRest)
}

public struct TweenShadow<T> {
  public let enabled: ReactiveProperty<Bool>
  public let state: ReactiveProperty<MotionState>
  public let duration: ReactiveProperty<CGFloat>
  public let delay: ReactiveProperty<CGFloat>
  public let repeatCount: ReactiveProperty<CGFloat>
  public let repeatDuration: ReactiveProperty<CGFloat>
  public let autoreverses: ReactiveProperty<Bool>
  public let values: ReactiveProperty<[T]>
  public let offsets: ReactiveProperty<[CGFloat]>
  public let timingFunctions: ReactiveProperty<[CAMediaTimingFunction]>
  public let timeline: Timeline?

  init(of tween: Tween<T>) {
    self.enabled = tween.enabled
    self.state = tween._state
    self.duration = tween.duration
    self.repeatCount = tween.repeatCount
    self.repeatDuration = tween.repeatDuration
    self.autoreverses = tween.autoreverses
    self.delay = tween.delay
    self.values = tween.values
    self.offsets = tween.offsets
    self.timingFunctions = tween.timingFunctions
    self.timeline = tween.timeline
  }
}
