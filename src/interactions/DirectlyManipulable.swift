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
 Allows a view to be directly manipulated with a combination of drag, rotation, and scale gestures.

 Composed of three primary sub-interactions: Draggable, Rotatable, and Scalable.

 If the sub-interaction gesture recognizers do not have an associated delegate, then this
 interaction will become the delegate and allow the gestures to recognize simultaneously
 uncoditionally.

 When other gesture recognizers are in play, it is recommended that you make use of the
 `.withExistingRecognizer` configuration option. Provide a gesture recognizer that already has a
 delegate associated with it and the relevant delegate methods implemented to support simultaneous
 recognition that doesn't conflict with the other gesture recognizers.
 */
public final class DirectlyManipulable: NSObject, Interaction, Togglable, Stateful {
  /**
   The interaction governing drag behaviors.
   */
  public let draggable: Draggable

  /**
   The interaction governing rotation behaviors.
   */
  public let rotatable: Rotatable

  /**
   The interaction governing scale behaviors.
   */
  public let scalable: Scalable

  /**
   Creates a new interaction with the provided sub-interactions.

   If no arguments are provided, then the default behavior is to create a new gesture recognizer for
   each sub-interaction and associate it with the target view upon association. Each gesture
   recognizer's delegate will also be configured to allow simultaneous recognition unconditionally.
   */
  public init(draggable: Draggable = Draggable(), rotatable: Rotatable = Rotatable(), scalable: Scalable = Scalable()) {
    self.draggable = draggable
    self.rotatable = rotatable
    self.scalable = scalable
  }

  public func add(to view: UIView, withRuntime runtime: MotionRuntime, constraints: NoConstraints) {
    for gestureRecognizer in [draggable.nextGestureRecognizer,
                              rotatable.nextGestureRecognizer,
                              scalable.nextGestureRecognizer] as [UIGestureRecognizer?] {
                                if gestureRecognizer?.delegate == nil {
                                  gestureRecognizer?.delegate = self
                                }
    }

    runtime.connect(enabled, to: draggable.enabled)
    runtime.connect(enabled, to: rotatable.enabled)
    runtime.connect(enabled, to: scalable.enabled)

    let gestures: [UIGestureRecognizer?] = [rotatable.nextGestureRecognizer, scalable.nextGestureRecognizer]
    let anchorPointRecognizers = gestures.compactMap { $0 }
    let adjustsAnchorPoint = AdjustsAnchorPoint(gestureRecognizers: anchorPointRecognizers)
    runtime.add(adjustsAnchorPoint, to: view)

    aggregateState.observe(state: draggable.state, withRuntime: runtime)
    aggregateState.observe(state: rotatable.state, withRuntime: runtime)
    aggregateState.observe(state: scalable.state, withRuntime: runtime)

    runtime.add(draggable, to: view)
    runtime.add(rotatable, to: view)
    runtime.add(scalable, to: view)
  }

  /**
   The current state of the interaction.
   */
  public var state: MotionObservable<MotionState> {
    return aggregateState.asStream()
  }

  public var enabled = createProperty(withInitialValue: true)

  let aggregateState = AggregateMotionState()
}

extension DirectlyManipulable: UIGestureRecognizerDelegate {
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    // This is overly simple, but works in isolated situations. If there are other gesture
    // recognizers in play then the user of this interaction may want to consider creating and
    // managing their own gesture recognizers.
    return true
  }
}
