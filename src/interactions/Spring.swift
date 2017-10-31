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

/**
 The default stiffness configuration.
 */
public let defaultSpringStiffness: CGFloat = 342

/**
 The default damping configuration.
 */
public let defaultSpringDamping: CGFloat = 30

/**
 The default mass configuration.
 */
public let defaultSpringMass: CGFloat = 1

/**
 A spring pulls a value from an initial position to a destination using a physical simulation of a
 dampened oscillator.

 A spring can be associated with many properties. Each property receives its own distinct simulator
 that reads the property as the initial value and pulls the value towards the destination.
 Configuration values are shared across all running instances.

 **Constraints**

 T-value constraints may be applied to this interaction.
 */
public class Spring<T>: Interaction, Togglable, Stateful where T: ZeroableAndSubtractable {
  /**
   Creates a spring with a given threshold and system.

   - parameter threshold: The threshold of movement defining the completion of the spring simulation. This parameter is not used by the Core Animation system and can be left as a default value.
   - parameter system: The system that should be used to drive this spring.
   */
  public init(threshold: CGFloat = 1, system: @escaping SpringToStream<T> = coreAnimation) {
    self.threshold = createProperty(withInitialValue: threshold)
    self.system = system
  }

  /**
   The initial velocity of the spring.

   Applied to the physical simulation only when it starts.
   */
  public let initialVelocity = createProperty(withInitialValue: T.zero() as! T)

  /**
   The destination value of the spring represented as a property.

   Changing this property will immediately affect the spring simulation.
   */
  public let destination = createProperty(withInitialValue: T.zero() as! T)

  /**
   Stiffness defines how quickly the spring's value moves towards its destination.

   Higher stiffness means higher initial velocity and more overshoot.
   */
  public let stiffness = createProperty(withInitialValue: defaultSpringStiffness)

  /**
   Damping defines how quickly the spring's velocity slows down.

   Higher damping means quicker deceleration and less overshoot.
   */
  public let damping = createProperty(withInitialValue: defaultSpringDamping)

  /**
   The mass affects the value's acceleration.

   Higher mass means slower acceleration and deceleration.
   */
  public let mass = createProperty(withInitialValue: defaultSpringMass)

  /**
   The suggested duration of the spring represented as a property.

   This property may not be supported by all animation systems.

   A value of 0 means this property will be ignored.
   */
  public let suggestedDuration = createProperty(withInitialValue: 0)

  /**
   The value used when determining completion of the spring simulation.
   */
  public let threshold: ReactiveProperty<CGFloat>

  /**
   Whether or not the spring is currently taking effect.

   Enabling a previously disabled spring will restart the animation from the current initial value.
   */
  public let enabled = createProperty(withInitialValue: true)

  /**
   The current state of the spring animation.
   */
  public var state: MotionObservable<MotionState> {
    return aggregateState.asStream()
  }

  public func add(to property: ReactiveProperty<T>,
                  withRuntime runtime: MotionRuntime,
                  constraints applyConstraints: ConstraintApplicator<T>? = nil) {
    let shadow = SpringShadow(of: self, initialValue: property)
    aggregateState.observe(state: shadow.state, withRuntime: runtime)
    var stream = system(shadow)
    if let applyConstraints = applyConstraints {
      stream = applyConstraints(stream)
    }
    runtime.connect(stream, to: property)
  }

  fileprivate let system: SpringToStream<T>
  private let aggregateState = AggregateMotionState()

  private var activeSprings = Set<SpringShadow<T>>()
}

public struct SpringShadow<T>: Hashable where T: ZeroableAndSubtractable {
  public let enabled: ReactiveProperty<Bool>
  public let state = createProperty(withInitialValue: MotionState.atRest)
  public let initialValue: ReactiveProperty<T>
  public let initialVelocity: ReactiveProperty<T>
  public let destination: ReactiveProperty<T>
  public let stiffness: ReactiveProperty<CGFloat>
  public let damping: ReactiveProperty<CGFloat>
  public let mass: ReactiveProperty<CGFloat>
  public let suggestedDuration: ReactiveProperty<CGFloat>
  public let threshold: ReactiveProperty<CGFloat>

  init(of spring: Spring<T>, initialValue: ReactiveProperty<T>) {
    self.enabled = spring.enabled
    self.initialValue = initialValue
    self.initialVelocity = spring.initialVelocity
    self.destination = spring.destination
    self.stiffness = spring.stiffness
    self.damping = spring.damping
    self.mass = spring.mass
    self.suggestedDuration = spring.suggestedDuration
    self.threshold = spring.threshold
  }

  private let uuid = NSUUID().uuidString
  public var hashValue: Int {
    return uuid.hashValue
  }

  public static func ==(lhs: SpringShadow<T>, rhs: SpringShadow<T>) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}
