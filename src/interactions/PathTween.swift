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
 A path tween is an interpolation along a two-dimensional path.
 */
public final class PathTween: Interaction, Togglable, Stateful {

  /**
   The duration of the animation in seconds.
   */
  public let duration: ReactiveProperty<CGFloat>

  /**
   The delay of the animation in seconds.
   */
  public let delay = createProperty("PathTween.delay", withInitialValue: 0)

  /**
   The path this animation will follow.
   */
  public let path: ReactiveProperty<CGPath>

  /**
   An optional timeline that may scrub this tween animation.

   If provided, this tween is expected to be timed in relation to the timeline's beginTime.
   */
  public let timeline: Timeline?

  /**
   Whether or not the tween animation is currently taking effect.

   Enabling a previously disabled tween will restart the animation from the beginning.
   */
  public let enabled = createProperty("PathTween.enabled", withInitialValue: true)

  /**
   The current state of the tween animation.
   */
  public var state: MotionObservable<MotionState> {
    return _state.asStream()
  }

  /**
   Initializes a path tween instance with its required properties.
   */
  public init(duration: CGFloat, path: CGPath, system: @escaping PathTweenToStream<CGPoint> = coreAnimation, timeline: Timeline? = nil) {
    self.duration = createProperty("PathTween.duration", withInitialValue: duration)
    self.path = createProperty("PathTween.path", withInitialValue: path)
    self.system = system
    self.timeline = timeline
  }

  /**
   Initializes a path tween instance with its required properties.
   */
  convenience public init(duration: DispatchTimeInterval, path: CGPath, system: @escaping PathTweenToStream<CGPoint> = coreAnimation, timeline: Timeline? = nil) {
    let durationInSeconds = duration.toSeconds()
    self.init(duration: durationInSeconds, path: path, system: system, timeline: timeline)
  }

  /**
   Initializes a path tween instance with a default duration of 0 and an empty path.

   The duration and path should be modified after initialization in order to configure the
   animation.
   */
  public init(system: @escaping PathTweenToStream<CGPoint> = coreAnimation, timeline: Timeline? = nil) {
    self.duration = createProperty("PathTween.duration", withInitialValue: 0)
    self.path = createProperty("PathTween.path", withInitialValue: UIBezierPath().cgPath)
    self.system = system
    self.timeline = timeline
  }

  public func add(to property: ReactiveProperty<CGPoint>, withRuntime runtime: MotionRuntime, constraints: NoConstraints) {
    runtime.connect(asStream(), to: property)
  }

  public let metadata = Metadata("Path Tween")

  fileprivate var stream: MotionObservable<CGPoint>?
  fileprivate let system: PathTweenToStream<CGPoint>
  fileprivate let _state = createProperty("PathTween._state", withInitialValue: MotionState.atRest)
}

public struct PathTweenShadow {
  public let enabled: ReactiveProperty<Bool>
  public let state: ReactiveProperty<MotionState>
  public let duration: ReactiveProperty<CGFloat>
  public let delay: ReactiveProperty<CGFloat>
  public let path: ReactiveProperty<CGPath>
  public let timeline: Timeline?

  init(of tween: PathTween) {
    self.enabled = tween.enabled
    self.state = tween._state
    self.duration = tween.duration
    self.delay = tween.delay
    self.path = tween.path
    self.timeline = tween.timeline
  }
}

extension PathTween: MotionObservableConvertible {
  public func asStream() -> MotionObservable<CGPoint> {
    if stream == nil {
      stream = system(PathTweenShadow(of: self))._remember()
    }
    return stream!
  }
}
