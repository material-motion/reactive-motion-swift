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

extension MotionObservableConvertible where T: UIGestureRecognizer {

  /** Only forwards the gesture recognizer if its state matches the provided value. */
    public func whenRecognitionState(is state: UIGestureRecognizer.State) -> MotionObservable<T> {
    return _filter { value in
      return value.state == state
    }
  }

  /** Only forwards the gesture recognizer if its state matches any of the provided values. */
    public func whenRecognitionState(isAnyOf states: [UIGestureRecognizer.State]) -> MotionObservable<T> {
    return _filter { value in
      return states.contains(value.state)
    }
  }

  public func asMotionState() -> MotionObservable<MotionState> {
    return _nextOperator { value, next in
      if value is UITapGestureRecognizer {
        if value.state == .recognized {
          // Tap gestures are momentary, so we won't have another opportunity to send an .atRest event
          // downstream. To ensure that taps can be used to drive animations we simulate the .atRest
          // event by sending it immediately after the .active emission.
          next(.active)
          next(.atRest)
        } else {
          next(.atRest)
        }

      } else {
        next((value.state == .began || value.state == .changed) ? .active : .atRest)
      }
    }
  }

  public func active() -> MotionObservable<Bool> {
    return _map { value in
      return value.state == .began || value.state == .changed
    }
  }

  public func atRest() -> MotionObservable<Bool> {
    return _map { value in
      return value.state != .began && value.state != .changed
    }
  }
}
