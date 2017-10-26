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
 The default transition spring stiffness configuration.
 */
public let defaultTransitionSpringStiffness: CGFloat = 1000

/**
 The default transition spring damping configuration.
 */
public let defaultTransitionSpringDamping: CGFloat = 500

/**
 The default transition spring mass configuration.
 */
public let defaultTransitionSpringMass: CGFloat = 3

/**
 The default transition spring suggested duration.
 */
public let defaultTransitionSpringSuggestedDuration: CGFloat = 0.5

/**
 A transition spring pulls a value from one side of a transition to another.

 A transition spring can be associated with many properties. Each property receives its own distinct
 simulator that reads the property as the initial value and pulls the value towards the destination.
 Configuration values are shared across all running instances.

 **Directionality**

 The terms `back` and `fore` are used here to refer to the backward and forward destinations,
 respectively. View controller transitions move *forward* when being presented, and *backward* when
 being dismissed. This consistency of directionality makes it easy to describe the goal states for
 a transition in a consistent manner, regardless of the direction.

 **Initial value**

 When associated with a property, this interaction will assign an initial value to the property
 corresponding to the initial direction's oposite destination. E.g. if transitioning forward, the
 property will be initialized with the `back` value.

 **Constraints**

 T-value constraints may be applied to this interaction.
 */
public final class TransitionSpring<T>: Spring<T> where T: ZeroableAndSubtractable {

  /**
   The destination when the transition is moving backward.
   */
  public let backwardDestination: T

  /**
   The destination when the transition is moving forward.
   */
  public let forwardDestination: T

  /**
   Creates a transition spring with a given threshold and system.

   - parameter back: The destination to which the spring will pull the view when transitioning backward.
   - parameter fore: The destination to which the spring will pull the view when transitioning forward.
   - parameter direction: The spring will change its destination in reaction to this property's changes.
   - parameter threshold: The threshold of movement defining the completion of the spring simulation. This parameter is not used by the Core Animation system and can be left as a default value.
   - parameter system: The system that should be used to drive this spring.
   */
  public init(back backwardDestination: T,
              fore forwardDestination: T,
              direction: ReactiveProperty<TransitionDirection>,
              threshold: CGFloat = 1,
              system: @escaping SpringToStream<T> = coreAnimation) {
    self.backwardDestination = backwardDestination
    self.forwardDestination = forwardDestination
    self.initialValue = direction == .forward ? backwardDestination : forwardDestination

    self.toggledDestination = direction.rewrite([.backward: backwardDestination, .forward: forwardDestination])
    super.init(threshold: threshold, system: system)

    // Apply Core Animation transition spring defaults.
    damping.value = defaultTransitionSpringDamping
    stiffness.value = defaultTransitionSpringStiffness
    mass.value = defaultTransitionSpringMass
    suggestedDuration.value = defaultTransitionSpringSuggestedDuration
  }

  public override func add(to property: ReactiveProperty<T>,
                           withRuntime runtime: MotionRuntime,
                           constraints: ConstraintApplicator<T>? = nil) {
    property.value = initialValue

    runtime.connect(toggledDestination, to: destination)
    super.add(to: property, withRuntime: runtime, constraints: constraints)
  }

  private let initialValue: T
  private let toggledDestination: MotionObservable<T>
}
