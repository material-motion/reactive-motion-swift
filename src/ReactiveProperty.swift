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

/**
 Creates a property with an initial value of zero.
 */
public func createProperty<T>() -> ReactiveProperty<T> where T: Zeroable {
  return ReactiveProperty(initialValue: T.zero() as! T)
}

/**
 Creates a CGFloat property with an initial value of zero.
 */
public func createProperty() -> ReactiveProperty<CGFloat> {
  return ReactiveProperty(initialValue: 0)
}

/**
 Creates a property with a given initial value.
 */
public func createProperty<T>(withInitialValue initialValue: T) -> ReactiveProperty<T> {
  return ReactiveProperty(initialValue: initialValue)
}

/**
 Creates a CGFloat property with a given initial Int value.

 If you need a ReactiveProperty<Int> instance, use ReactiveProperty's initializer instead.
 */
public func createProperty(withInitialValue initialValue: Int) -> ReactiveProperty<CGFloat> {
  return ReactiveProperty(initialValue: CGFloat(initialValue))
}

/**
 A reactive property represents an observable value.
 */
public final class ReactiveProperty<T> {

  /**
   The value backing this property.

   Writes to this value will immediately be propagated to all subscribed observers.
   */
  public var value: T {
    didSet {
      _externalWrite?(value)

      for observer in observers {
        observer.next(value)
      }
    }
  }

  /**
   Creates a new anonymous property.
   */
  public init(initialValue: T) {
    self.value = initialValue
    self._externalWrite = nil
    self._coreAnimation = nil
  }

  /**
   Creates a property that writes to some external information.
   */
  init(initialValue: T, externalWrite: @escaping NextChannel<T>) {
    self.value = initialValue
    self._externalWrite = externalWrite
    self._coreAnimation = nil
  }

  /**
   Creates a property that writes to some external information and supports Core Animation.
   */
  init(initialValue: T, externalWrite: @escaping NextChannel<T>, coreAnimation: @escaping CoreAnimationChannel) {
    self.value = initialValue
    self._externalWrite = externalWrite
    self._coreAnimation = coreAnimation
  }

  func visualize(_ view: UIView, in containerView: UIView) {
    shouldVisualizeMotion?(view, containerView)
  }
  var shouldVisualizeMotion: ((UIView, UIView) -> Void)?

  /**
   Forwards the invocation to the channel if a core animation channel was provided to this property,
   otherwise throws an assertion.
   */
  func coreAnimation(_ event: CoreAnimationChannelEvent) {
    _coreAnimation?(event)

    let transformedEvent: CoreAnimationChannelEvent
    switch event {
    case .add(var info):
      // This is a hack-fix to ensure that animations don't over-complete they're connected to other
      // properties.
      // Related to https://github.com/material-motion/material-motion-swift/issues/65
      info.onCompletion = nil
      transformedEvent = .add(info)
    default:
      transformedEvent = event
    }
    for observer in observers {
      observer.coreAnimation?(transformedEvent)
    }
  }

  private let _externalWrite: NextChannel<T>?
  private let _coreAnimation: CoreAnimationChannel?

  fileprivate var observers: [MotionObserver<T>] = []
}

extension ReactiveProperty where T: Equatable {
  /**
   Two reactive properties are equal if their backing values are equal.
   */
  public static func == (left: ReactiveProperty<T>, right: ReactiveProperty<T>) -> Bool {
    return left.value == right.value
  }

  public static func == (left: ReactiveProperty<T>, right: T) -> Bool {
    return left.value == right
  }

  /**
   Two reactive properties are not equal if their backing values are not equal.
   */
  public static func != (left: ReactiveProperty<T>, right: ReactiveProperty<T>) -> Bool {
    return left.value != right.value
  }

  public static func != (left: ReactiveProperty<T>, right: T) -> Bool {
    return left.value != right
  }
}

// Reactive properties can be used as streams.
extension ReactiveProperty: MotionObservableConvertible {
  public func asStream() -> MotionObservable<T> {
    return MotionObservable<T> { observer in
      self.observers.append(observer)

      observer.next(self.value)

      return {
        if let index = self.observers.firstIndex(where: { $0 === observer }) {
          self.observers.remove(at: index)
        }
      }
    }
  }
}
